import 'package:sqflite/sqflite.dart';

Future<void> upgradeToV5(DatabaseExecutor db) async {
  await db.execute(
    'ALTER TABLE notes ADD COLUMN habit_id TEXT REFERENCES habits(id) ON DELETE SET NULL',
  );
  await db.execute('CREATE INDEX notes_day_index ON notes(day)');
  await db.execute('CREATE INDEX notes_habit_index ON notes(habit_id)');
}

Future<void> upgradeToV4(DatabaseExecutor db) async {
  await db.execute(
    'ALTER TABLE tasks ADD COLUMN resident INTEGER NOT NULL DEFAULT 0 CHECK(resident IN (0,1))',
  );
  await db.execute('ALTER TABLE tasks ADD COLUMN start_day TEXT');
  await db.execute(
    'ALTER TABLE tasks ADD COLUMN archived INTEGER NOT NULL DEFAULT 0 CHECK(archived IN (0,1))',
  );
  await db.execute(
    'CREATE TABLE task_entries(task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE, day TEXT NOT NULL, PRIMARY KEY(task_id,day))',
  );
}

Future<void> upgradeToV3(DatabaseExecutor db) async {
  await db.execute(
    'CREATE TABLE reminders (habit_id TEXT PRIMARY KEY REFERENCES habits(id) ON DELETE CASCADE, enabled INTEGER NOT NULL CHECK(enabled IN (0,1)), minutes TEXT NOT NULL, revision INTEGER NOT NULL CHECK(revision>=0))',
  );
}

Future<void> upgradeToV2(DatabaseExecutor db) async {
  await db.execute(
    'CREATE TABLE habit_groups (id TEXT PRIMARY KEY, name TEXT NOT NULL, position INTEGER NOT NULL)',
  );
  await db.execute(
    "ALTER TABLE habits ADD COLUMN context TEXT NOT NULL DEFAULT 'anytime'",
  );
  await db.execute(
    'ALTER TABLE habits ADD COLUMN group_id TEXT REFERENCES habit_groups(id) ON DELETE SET NULL',
  );
  await db.execute(
    'ALTER TABLE habits ADD COLUMN position INTEGER NOT NULL DEFAULT 0',
  );
  await db.execute(
    "ALTER TABLE habits ADD COLUMN schedule TEXT NOT NULL DEFAULT 'weekdays'",
  );
  await db.execute(
    'ALTER TABLE habits ADD COLUMN interval_days INTEGER NOT NULL DEFAULT 1',
  );
  await db.execute(
    'ALTER TABLE habits ADD COLUMN weekly_goal INTEGER NOT NULL DEFAULT 3',
  );
  await db.execute('UPDATE habits SET position = rowid');
  await db.execute(
    'CREATE TABLE plans (habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE, effective_day TEXT NOT NULL, target INTEGER NOT NULL CHECK(target>0), unit TEXT NOT NULL, schedule TEXT NOT NULL, weekdays INTEGER NOT NULL, interval_days INTEGER NOT NULL, weekly_goal INTEGER NOT NULL, PRIMARY KEY(habit_id,effective_day))',
  );
  await db.execute(
    'INSERT INTO plans SELECT id,start_day,target,unit,schedule,weekdays,interval_days,weekly_goal FROM habits',
  );
  await db.execute(
    'CREATE TABLE runtime (id INTEGER PRIMARY KEY CHECK(id=1), generation INTEGER NOT NULL)',
  );
  await db.insert('runtime', {'id': 1, 'generation': 0});
  await db.execute(
    'CREATE TABLE recovery (id INTEGER PRIMARY KEY CHECK(id=1), snapshot TEXT NOT NULL)',
  );
}
