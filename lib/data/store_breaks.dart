part of 'app_store.dart';

extension StoreBreaks on AppStore {
  Future<List<HabitBreak>> breaks() async => (await _executor.query(
    'habit_breaks',
    orderBy: 'start_day,id',
  )).map(HabitBreak.fromMap).toList();
  Future<void> addBreak(HabitBreak rest, {required Day today}) =>
      _transaction((txn) async {
        Day.parse(rest.start.key);
        if (rest.end != null) Day.parse(rest.end!.key);
        if (!rest.valid) throw ArgumentError('Invalid rest');
        final rows = await txn.query(
          'habits',
          where: 'id=?',
          whereArgs: [rest.habitId],
        );
        if (rows.isEmpty) throw StateError('Habit missing');
        final h = Habit.fromMap(rows.single);
        if (h.archived ||
            rest.start.compareTo(h.startDay) < 0 ||
            (rest.kind == BreakKind.skip
                ? rest.start.compareTo(today) > 0
                : rest.start.compareTo(today) < 0) ||
            (rest.kind == BreakKind.pause && rest.start != today)) {
          throw ArgumentError('Invalid rest date');
        }
        final saved = (await txn.query(
          'habit_breaks',
          where: 'habit_id=?',
          whereArgs: [h.id],
        )).map(HabitBreak.fromMap).toList();
        if (saved.any(
          (b) =>
              b.id == rest.id &&
              b.habitId == rest.habitId &&
              b.start == rest.start &&
              b.end == rest.end &&
              b.kind == rest.kind,
        )) {
          return;
        }
        if (saved.any(rest.overlaps)) throw StateError('Overlapping rest');
        if (rest.kind == BreakKind.skip &&
            (await txn.query(
              'entries',
              where: 'habit_id=? AND day=?',
              whereArgs: [h.id, rest.start.key],
            )).isNotEmpty) {
          throw StateError('A recorded day cannot be skipped');
        }
        await txn.insert('habit_breaks', rest.toMap());
      });
  Future<void> endBreak(
    HabitBreak expected, {
    required Day today,
  }) => _transaction((txn) async {
    final rows = await txn.query(
      'habit_breaks',
      where: 'id=?',
      whereArgs: [expected.id],
    );
    if (rows.isEmpty) return; // Explicit removal is idempotent, never toggles.
    final current = HabitBreak.fromMap(rows.single);
    if (current.habitId != expected.habitId ||
        current.start != expected.start ||
        current.end != expected.end ||
        current.kind != expected.kind) {
      throw StateError('Rest changed');
    }
    if (current.kind == BreakKind.pause && current.start.compareTo(today) > 0) {
      throw StateError('Clock precedes pause');
    }
    if (current.kind == BreakKind.skip || current.start.compareTo(today) >= 0) {
      await txn.delete('habit_breaks', where: 'id=?', whereArgs: [current.id]);
    } else {
      if (current.end != null && current.end!.compareTo(today) < 0) {
        throw StateError('Past rest is preserved');
      }
      await txn.update(
        'habit_breaks',
        {'end_day': today.plus(-1).key},
        where: 'id=?',
        whereArgs: [current.id],
      );
    }
  });
}
