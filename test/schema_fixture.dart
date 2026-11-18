import 'package:sqflite/sqflite.dart';

/// Tests that downgrade today's database must remove schema12, schema13 and schema14 objects first.
Future<void> discardV12Fixture(DatabaseExecutor db) async {
  for (final row in await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='trigger' AND (name LIKE 'item_%' OR name LIKE 'event_%' OR name LIKE 'reminder_task_%' OR name LIKE 'note_images_%')",
  )) {
    await db.execute('DROP TRIGGER "${row['name']}"');
  }
  await db.execute('DROP TABLE IF EXISTS note_images');
  await db.execute('DROP TABLE IF EXISTS task_reminders');
  await db.execute('DROP TABLE IF EXISTS record_events');
  await db.execute('DROP TABLE IF EXISTS item_revisions');
}
