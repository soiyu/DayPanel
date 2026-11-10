part of 'app_store.dart';

extension StoreBackup on AppStore {
  Future<void> importLegacy(
    LegacyImport source,
    Map<String, LegacySchedule> selected, {
    required Day today,
    required bool chinese,
    Future<void> Function(String)? fault,
  }) => _transaction((txn) async {
    final current = await _snapshot(txn, DateTime.now());
    final merged = source.appendTo(
      current,
      selected,
      today: today,
      chinese: chinese,
    );
    await restoreSnapshot(merged, fault: fault);
  });

  Future<BackupSnapshot> exportSnapshot({DateTime? now}) =>
      _transaction((txn) => _snapshot(txn, now ?? DateTime.now()));
  Future<BackupSnapshot> _snapshot(
    DatabaseExecutor executor,
    DateTime now,
  ) async {
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in BackupSnapshot.tableNames) {
      tables[table] = await executor.query(table, orderBy: 'rowid');
    }
    return BackupSnapshot.fromTables(tables, now.toUtc());
  }

  Future<BackupSnapshot?> recoverySnapshot() async {
    final rows = await _executor.query('recovery', where: 'id=1');
    if (rows.isEmpty) return null;
    return BackupSnapshot.decode(
      utf8.encode(rows.single['snapshot'] as String),
    );
  }

  Future<void> restoreSnapshot(
    BackupSnapshot snapshot, {
    bool rollback = false,
    Future<void> Function(String)? fault,
  }) async {
    // Revalidate the immutable public snapshot before opening the replacement transaction.
    final validated = BackupSnapshot.decode(snapshot.encode());
    await _transaction((txn) async {
      final previous = await _snapshot(txn, DateTime.now());
      await txn.insert('recovery', {
        'id': 1,
        'snapshot': utf8.decode(previous.encode()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (final table in [
        'record_events',
        'habit_breaks',
        'habit_activity',
        'cards',
        'task_entries',
        'reminders',
        'entries',
        'plans',
        'habits',
        'habit_groups',
        'tasks',
        'notes',
        'settings',
      ]) {
        await txn.delete(table);
      }
      if (fault != null) await fault('cleared');
      final batch = txn.batch();
      for (final table in BackupSnapshot.tableNames) {
        for (final row in validated.tables[table]!) {
          batch.insert(table, row);
        }
      }
      await batch.commit(noResult: true);
      if (fault != null) await fault('inserted');
      if ((await txn.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
        throw StateError('Invalid references');
      }
      await txn.rawUpdate(
        'UPDATE runtime SET generation=generation+1 WHERE id=1',
      );
      if (rollback) await txn.delete('recovery');
      if (fault != null) await fault('before_commit');
    });
  }
}
