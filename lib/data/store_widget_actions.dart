part of 'app_store.dart';

extension StoreWidgetActions on AppStore {
  Future<int> widgetRevision() async =>
      (await _executor.query('runtime')).single['revision'] as int;

  /// Compare and set in the same SQLite transaction as the ordinary rule path.
  /// A display revision is NOT a click id. No operation toggles the current value.
  Future<bool> applyWidgetValue({
    required String kind,
    required String id,
    required Day day,
    required int generation,
    required int revision,
    required Object? expectedValue,
    int? itemRevision,
    required bool completed,
    DateTime Function()? clock,
    Future<bool> Function()? bindingStillValid,
  }) => inGeneration(generation, () async {
    Day today() => Day((clock ?? DateTime.now)());
    if (day != today()) return false;
    if (itemRevision != null) {
      final rows = await _executor.query(
        'item_revisions',
        where: 'kind=? AND id=?',
        whereArgs: [kind, id],
      );
      if (rows.isEmpty || rows.single['revision'] != itemRevision) return false;
    } else if (revision != await widgetRevision()) {
      return false;
    }
    if (bindingStillValid != null && !await bindingStillValid()) return false;
    if (kind == 'habit') {
      final rows = await _executor.query(
        'habits',
        where: 'id=?',
        whereArgs: [id],
      );
      if (rows.isEmpty || Habit.fromMap(rows.single).kind != HabitKind.check) {
        return false;
      }
      final entry = await _executor.query(
        'entries',
        where: 'habit_id=? AND day=?',
        whereArgs: [id, day.key],
      );
      final actual = entry.isEmpty ? null : entry.single['value'];
      if (actual != expectedValue || day != today()) return false;
      await setRecord(id, day, completed ? 1000 : null, today: today());
    } else if (kind == 'task') {
      final rows = await _executor.query(
        'tasks',
        where: 'id=?',
        whereArgs: [id],
      );
      if (rows.isEmpty) return false;
      final task = SmallTask.fromMap(rows.single);
      if (task.archived) return false;
      Object? actual = task.completedDay?.key;
      if (task.resident) {
        final entries = await _executor.query(
          'task_entries',
          where: 'task_id=? AND day=?',
          whereArgs: [id, day.key],
        );
        actual = entries.isEmpty ? null : day.key;
      }
      if (actual != expectedValue || day != today()) return false;
      if (task.resident) {
        await setResidentRecord(id, day, completed, today: today());
      } else {
        await completeTask(id, completed, today());
      }
    } else {
      return false;
    }
    return true;
  });
}
