import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';

class AppStore {
  AppStore._(this.db);
  final Database db;

  static Future<AppStore> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath =
        path ?? p.join(await f.getDatabasesPath(), 'daypanel_flutter.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE habits (id TEXT PRIMARY KEY, title TEXT NOT NULL, kind TEXT NOT NULL, start_day TEXT NOT NULL, target INTEGER NOT NULL CHECK(target > 0), unit TEXT NOT NULL, weekdays INTEGER NOT NULL CHECK(weekdays BETWEEN 1 AND 127), icon INTEGER NOT NULL, archived INTEGER NOT NULL DEFAULT 0)',
          );
          await db.execute(
            'CREATE TABLE entries (habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE, day TEXT NOT NULL, value INTEGER NOT NULL CHECK(value >= 0), PRIMARY KEY(habit_id, day))',
          );
          await db.execute(
            'CREATE TABLE tasks (id TEXT PRIMARY KEY, title TEXT NOT NULL, due_day TEXT, completed_day TEXT)',
          );
          await db.execute(
            'CREATE TABLE notes (id TEXT PRIMARY KEY, body TEXT NOT NULL, day TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
        },
      ),
    );
    return AppStore._(db);
  }

  Future<void> close() => db.close();
  Future<List<Habit>> habits() async =>
      (await db.query('habits', orderBy: 'rowid')).map(Habit.fromMap).toList();
  Future<List<SmallTask>> tasks() async => (await db.query(
    'tasks',
    orderBy: 'rowid DESC',
  )).map(SmallTask.fromMap).toList();
  Future<List<Note>> notes() async => (await db.query(
    'notes',
    orderBy: 'day DESC, rowid DESC',
  )).map(Note.fromMap).toList();
  Future<List<HabitEntry>> entries() async => (await db.query('entries'))
      .map(
        (m) => HabitEntry(
          habitId: m['habit_id'] as String,
          day: Day.parse(m['day'] as String),
          value: m['value'] as int,
        ),
      )
      .toList();
  Future<Map<String, String>> settings() async => {
    for (final m in await db.query('settings'))
      m['key'] as String: m['value'] as String,
  };

  Future<void> saveHabit(Habit habit, {bool create = false}) async {
    if (habit.title.trim().isEmpty ||
        habit.title.length > 100 ||
        habit.target <= 0 ||
        habit.target > 999999999999 ||
        (habit.kind == HabitKind.check && habit.target != 1000) ||
        habit.weekdays < 1 ||
        habit.weekdays > 127 ||
        habit.unit.length > 12 ||
        habit.icon < 0 ||
        habit.icon > 5) {
      throw ArgumentError('Invalid habit');
    }
    await db.transaction((txn) async {
      if (create) {
        await txn.insert('habits', habit.toMap());
      } else {
        final old = await txn.query(
          'habits',
          where: 'id = ?',
          whereArgs: [habit.id],
        );
        if (old.isEmpty ||
            old.single['kind'] != habit.kind.name ||
            old.single['start_day'] != habit.startDay.key) {
          throw StateError('Habit missing or incompatible edit');
        }
        await txn.update(
          'habits',
          habit.toMap(),
          where: 'id = ?',
          whereArgs: [habit.id],
        );
      }
    });
  }

  Future<void> setArchived(String id, bool archived) async {
    if (await db.update(
          'habits',
          {'archived': archived ? 1 : 0},
          where: 'id = ?',
          whereArgs: [id],
        ) !=
        1) {
      throw StateError('Habit missing');
    }
  }

  Future<void> setRecord(
    String id,
    Day day,
    int? value, {
    required Day today,
  }) async {
    await db.transaction((txn) async {
      final rows = await txn.query('habits', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) throw StateError('Habit missing');
      final h = Habit.fromMap(rows.single);
      if (h.archived ||
          day.compareTo(h.startDay) < 0 ||
          day.compareTo(today) > 0 ||
          (value != null &&
              (value < 0 ||
                  value > 999999999999 ||
                  (h.kind == HabitKind.check &&
                      value != 0 &&
                      value != 1000)))) {
        throw ArgumentError('Invalid record');
      }
      if (value == null) {
        await txn.delete(
          'entries',
          where: 'habit_id = ? AND day = ?',
          whereArgs: [id, day.key],
        );
      } else {
        await txn.insert('entries', {
          'habit_id': id,
          'day': day.key,
          'value': value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> saveTask(SmallTask task, {bool create = false}) async {
    if (task.title.trim().isEmpty || task.title.length > 100) {
      throw ArgumentError('Invalid task');
    }
    if (create) {
      await db.insert('tasks', task.toMap());
    } else {
      // Editing text/date must not resurrect a deleted task or overwrite completion.
      if (await db.update(
            'tasks',
            {'title': task.title, 'due_day': task.dueDay?.key},
            where: 'id = ?',
            whereArgs: [task.id],
          ) !=
          1) {
        throw StateError('Task missing');
      }
    }
  }

  Future<void> completeTask(String id, bool done, Day today) async {
    await db.transaction((txn) async {
      final rows = await txn.query('tasks', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) throw StateError('Task missing');
      if (done && rows.single['completed_day'] != null) {
        return; // Keep first completion date.
      }
      await txn.update(
        'tasks',
        {'completed_day': done ? today.key : null},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> saveNote(Note note, {bool create = false}) async {
    if (note.body.trim().isEmpty || note.body.length > 10000) {
      throw ArgumentError('Invalid note');
    }
    if (create) {
      await db.insert('notes', note.toMap());
    } else if (await db.update(
          'notes',
          note.toMap(),
          where: 'id = ?',
          whereArgs: [note.id],
        ) !=
        1) {
      throw StateError('Note missing');
    }
  }

  Future<void> remove(String table, String id) async {
    if (!{'habits', 'tasks', 'notes'}.contains(table)) {
      throw ArgumentError('Invalid entity');
    }
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> preference(String key, String value) async {
    if (key == 'locale' && !{'system', 'en', 'zh'}.contains(value) ||
        key == 'theme' && !{'system', 'light', 'dark'}.contains(value) ||
        !{'theme', 'locale'}.contains(key)) {
      throw ArgumentError('Invalid preference');
    }
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
