part of 'app_store.dart';

extension StoreEvents on AppStore {
  Future<List<RecordEvent>> recordEvents({String? habitId, Day? day}) async =>
      (await _executor.query(
        'record_events',
        where: [
          if (habitId != null) 'habit_id=?',
          if (day != null) 'day=?',
        ].join(' AND ').nullIfEmpty,
        whereArgs: [?habitId, if (day != null) day.key],
        orderBy: 'day,COALESCE(minute,-1),rowid',
      )).map(RecordEvent.fromMap).toList();

  Future<bool> addRecordEvent(
    RecordEvent event, {
    required Day today,
    int? expectedRevision,
  }) => _transaction((txn) async {
    final existing = await txn.query(
      'record_events',
      where: 'id=?',
      whereArgs: [event.id],
    );
    if (existing.isNotEmpty) {
      final old = RecordEvent.fromMap(existing.single);
      if (!old.deleted &&
          old.revision == 0 &&
          old.habitId == event.habitId &&
          old.day == event.day &&
          old.value == event.value &&
          old.minute == event.minute &&
          old.note == event.note &&
          old.kind == event.kind) {
        return false;
      }
      throw const RecordRevisionConflict();
    }
    if (expectedRevision != null &&
        (await txn.query('runtime')).single['revision'] != expectedRevision) {
      throw const RecordRevisionConflict();
    }
    if (event.id.isEmpty ||
        event.id.length > 128 ||
        event.kind != RecordEventKind.record ||
        event.deleted ||
        event.revision != 0 ||
        event.value <= 0 ||
        event.value > 999999999999 ||
        event.note.length > 500 ||
        (event.minute != null &&
            (event.minute! < 0 || event.minute! >= 1440))) {
      throw ArgumentError('Invalid event');
    }
    final habit = Habit.fromMap(
      (await txn.query(
        'habits',
        where: 'id=?',
        whereArgs: [event.habitId],
      )).single,
    );
    if (!habit.kind.isNumeric ||
        (habit.kind == HabitKind.count && event.value % 1000 != 0)) {
      throw ArgumentError('Invalid amount');
    }
    await txn.insert('record_events', event.toMap());
    return _summarizeEvents(txn, event.habitId, event.day, today);
  });

  Future<void> reviseRecordEvent(
    RecordEvent event, {
    required Day today,
    required int expectedRevision,
  }) => _transaction((txn) async {
    final rows = await txn.query(
      'record_events',
      where: 'id=?',
      whereArgs: [event.id],
    );
    if (rows.isEmpty) throw const RecordRevisionConflict();
    final old = RecordEvent.fromMap(rows.single);
    if (old.revision != expectedRevision ||
        old.deleted ||
        old.habitId != event.habitId ||
        old.day != event.day ||
        old.kind != event.kind) {
      throw const RecordRevisionConflict();
    }
    if ((!event.deleted &&
            event.kind == RecordEventKind.record &&
            event.value <= 0) ||
        event.note.length > 500 ||
        event.value.abs() > 999999999999 ||
        (event.kind != RecordEventKind.adjustment && event.value < 0) ||
        (event.minute != null &&
            (event.minute! < 0 || event.minute! >= 1440)) ||
        (event.kind != RecordEventKind.record && event.minute != null)) {
      throw ArgumentError('Invalid event');
    }
    final habit = Habit.fromMap(
      (await txn.query(
        'habits',
        where: 'id=?',
        whereArgs: [event.habitId],
      )).single,
    );
    if (!habit.kind.isNumeric ||
        (habit.kind == HabitKind.count && event.value % 1000 != 0)) {
      throw ArgumentError('Invalid amount');
    }
    await txn.update(
      'record_events',
      {
        ...event.toMap(),
        if (event.deleted) ...{'value': 0, 'minute': null, 'note': ''},
        'revision': old.revision + 1,
      },
      where: 'id=?',
      whereArgs: [event.id],
    );
    await _summarizeEvents(txn, event.habitId, event.day, today);
  });

  Future<bool> _summarizeEvents(
    Transaction txn,
    String id,
    Day day,
    Day today,
  ) async {
    final rows = await txn.rawQuery(
      'SELECT COUNT(*) AS n, COALESCE(SUM(value),0) AS total FROM record_events WHERE habit_id=? AND day=? AND deleted=0',
      [id, day.key],
    );
    return _setRecord(
      id,
      day,
      rows.single['n'] == 0 ? null : rows.single['total'] as int,
      today: today,
      updateLedger: false,
    );
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
