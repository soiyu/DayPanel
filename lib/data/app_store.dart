import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';
import 'schema.dart';
import '../domain/backup.dart';
import '../domain/reminder.dart';
import '../domain/achievement.dart';
part 'store_backup.dart';
part 'store_cards.dart';

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
        version: 6,
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
          await upgradeToV2(db);
          await upgradeToV3(db);
          await upgradeToV4(db);
          await upgradeToV5(db);
          await upgradeToV6(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await upgradeToV2(db);
          if (oldVersion < 3) await upgradeToV3(db);
          if (oldVersion < 4) await upgradeToV4(db);
          if (oldVersion < 5) await upgradeToV5(db);
          if (oldVersion < 6) await upgradeToV6(db);
        },
      ),
    );
    return AppStore._(db);
  }

  Future<void> close() => db.close();
  Future<List<TaskEntry>> taskEntries() async => (await db.query(
    'task_entries',
    orderBy: 'day DESC,task_id',
  )).map(TaskEntry.fromMap).toList();
  Future<List<HabitReminder>> reminders() async =>
      (await db.query('reminders')).map(HabitReminder.fromMap).toList();
  Future<void> saveReminder(HabitReminder reminder) async {
    if (!reminder.valid) throw ArgumentError('Invalid reminder');
    await db.transaction((txn) async {
      if ((await txn.query(
        'habits',
        where: 'id=?',
        whereArgs: [reminder.habitId],
      )).isEmpty) {
        throw StateError('Habit missing');
      }
      final old = await txn.query(
        'reminders',
        where: 'habit_id=?',
        whereArgs: [reminder.habitId],
      );
      final revision = old.isEmpty ? 0 : (old.single['revision'] as int) + 1;
      await txn.insert('reminders', {
        ...reminder.toMap(),
        'revision': revision,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Habit>> habits() async => (await db.query(
    'habits',
    orderBy: 'position,rowid',
  )).map(Habit.fromMap).toList();
  Future<List<HabitGroup>> groups() async => (await db.query(
    'habit_groups',
    orderBy: 'position,rowid',
  )).map(HabitGroup.fromMap).toList();
  Future<List<HabitPlan>> plans() async => (await db.query(
    'plans',
    orderBy: 'effective_day',
  )).map(HabitPlan.fromMap).toList();
  Future<int> generation() async =>
      (await db.query('runtime')).single['generation'] as int;
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

  Future<void> saveHabit(Habit habit, {bool create = false, Day? today}) async {
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
    if (habit.intervalDays < 1 ||
        habit.intervalDays > 365 ||
        habit.weeklyGoal < 1 ||
        habit.weeklyGoal > 7) {
      throw ArgumentError('Invalid schedule');
    }
    final date = today ?? Day(DateTime.now());
    await db.transaction((txn) async {
      if (create) {
        final last = await txn.rawQuery(
          'SELECT COALESCE(MAX(position),-1)+1 AS next FROM habits',
        );
        await txn.insert('habits', {
          ...habit.toMap(),
          'position': last.single['next'],
        });
        await txn.insert(
          'plans',
          HabitPlan.fromHabit(habit, habit.startDay).toMap(),
        );
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
        final oldHabit = Habit.fromMap(old.single);
        final desired = HabitPlan.fromHabit(habit, date.plus(1));
        final latestRows = await txn.query(
          'plans',
          where: 'habit_id=?',
          whereArgs: [habit.id],
          orderBy: 'effective_day DESC',
          limit: 1,
        );
        if (!desired.sameRules(HabitPlan.fromMap(latestRows.single))) {
          if (date.compareTo(oldHabit.startDay) < 0) {
            throw StateError('Clock precedes habit');
          }
          await txn.delete(
            'plans',
            where: 'habit_id=? AND effective_day>?',
            whereArgs: [habit.id, date.key],
          );
          final active = (await txn.query(
            'plans',
            where: 'habit_id=? AND effective_day<=?',
            whereArgs: [habit.id, date.key],
            orderBy: 'effective_day DESC',
            limit: 1,
          )).single;
          if (!desired.sameRules(HabitPlan.fromMap(active))) {
            await txn.insert('plans', desired.toMap());
          }
        }
        await txn.update(
          'habits',
          {
            ...habit.toMap(),
            'position': oldHabit.position,
            'archived': oldHabit.archived ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [habit.id],
        );
      }
    });
  }

  Future<void> saveGroup(HabitGroup group, {bool create = false}) async {
    if (group.name.trim().isEmpty || group.name.length > 40) {
      throw ArgumentError('Invalid group');
    }
    await db.transaction((txn) async {
      final existing = await txn.query('habit_groups');
      if (existing.any(
        (m) =>
            m['id'] != group.id &&
            (m['name'] as String).trim().toLowerCase() ==
                group.name.trim().toLowerCase(),
      )) {
        throw StateError('Duplicate group');
      }
      if (create) {
        final rows = await txn.rawQuery(
          'SELECT COALESCE(MAX(position),-1)+1 AS next FROM habit_groups',
        );
        await txn.insert('habit_groups', {
          ...group.toMap(),
          'name': group.name.trim(),
          'position': rows.single['next'],
        });
      } else if (await txn.update(
            'habit_groups',
            {'name': group.name.trim()},
            where: 'id=?',
            whereArgs: [group.id],
          ) !=
          1) {
        throw StateError('Group missing');
      }
    });
  }

  Future<void> removeGroup(String id) async =>
      db.delete('habit_groups', where: 'id=?', whereArgs: [id]);
  Future<void> reorderHabits(List<String> ids) async {
    await db.transaction((txn) async {
      final existing = (await txn.query(
        'habits',
      )).map((m) => m['id'] as String).toSet();
      if (ids.length != existing.length ||
          ids.toSet().length != ids.length ||
          !existing.containsAll(ids)) {
        throw ArgumentError('Invalid order');
      }
      final batch = txn.batch();
      for (var i = 0; i < ids.length; i++) {
        batch.update(
          'habits',
          {'position': i},
          where: 'id=?',
          whereArgs: [ids[i]],
        );
      }
      await batch.commit(noResult: true);
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

  Future<bool> setRecord(
    String id,
    Day day,
    int? value, {
    required Day today,
  }) async {
    return db.transaction((txn) async {
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
      final previous = await txn.query(
        'entries',
        where: 'habit_id=? AND day=?',
        whereArgs: [id, day.key],
      );
      final planRows = await txn.query(
        'plans',
        where: 'habit_id=? AND effective_day<=?',
        whereArgs: [id, day.key],
        orderBy: 'effective_day DESC',
        limit: 1,
      );
      final plan = HabitPlan.fromMap(planRows.single);
      final becameComplete =
          day == today &&
          value != null &&
          value >= plan.target &&
          (previous.isEmpty || (previous.single['value'] as int) < plan.target);
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
      if (becameComplete &&
          plan.schedule != ScheduleKind.weekly &&
          plan.scheduled(day)) {
        await earnCardIn(txn, day);
      }
      return becameComplete;
    });
  }

  Future<void> saveTask(
    SmallTask task, {
    bool create = false,
    Day? today,
  }) async {
    if (task.title.trim().isEmpty || task.title.length > 100) {
      throw ArgumentError('Invalid task');
    }
    if (task.resident
        ? (task.startDay == null ||
              task.dueDay != null ||
              task.completedDay != null)
        : (task.startDay != null || task.archived)) {
      throw ArgumentError('Invalid task type fields');
    }
    await db.transaction((txn) async {
      if (create) {
        if (task.resident &&
            (task.startDay != (today ?? Day(DateTime.now())) ||
                task.archived)) {
          throw ArgumentError('New resident task must start today');
        }
        await txn.insert('tasks', task.toMap());
      } else {
        final rows = await txn.query(
          'tasks',
          where: 'id=?',
          whereArgs: [task.id],
        );
        if (rows.isEmpty) throw StateError('Task missing');
        final previous = SmallTask.fromMap(rows.single);
        if (previous.resident != task.resident ||
            previous.startDay != task.startDay) {
          throw StateError('Task type and start date are immutable');
        }
        // Editing text/date must not resurrect a deleted task or overwrite completion.
        if (await txn.update(
              'tasks',
              {'title': task.title, 'due_day': task.dueDay?.key},
              where: 'id = ?',
              whereArgs: [task.id],
            ) !=
            1) {
          throw StateError('Task missing');
        }
      }
    });
  }

  Future<void> setResidentRecord(
    String id,
    Day day,
    bool done, {
    required Day today,
  }) async {
    await db.transaction((txn) async {
      final rows = await txn.query('tasks', where: 'id=?', whereArgs: [id]);
      if (rows.isEmpty) throw StateError('Task missing');
      final task = SmallTask.fromMap(rows.single);
      if (!task.resident ||
          task.archived ||
          day.compareTo(task.startDay!) < 0 ||
          day.compareTo(today) > 0) {
        throw ArgumentError('Invalid resident task date');
      }
      if (done) {
        await txn.insert('task_entries', {
          'task_id': id,
          'day': day.key,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        await txn.delete(
          'task_entries',
          where: 'task_id=? AND day=?',
          whereArgs: [id, day.key],
        );
      }
    });
  }

  Future<void> archiveTask(String id, bool archived) async {
    if (await db.update(
          'tasks',
          {'archived': archived ? 1 : 0},
          where: 'id=? AND resident=1',
          whereArgs: [id],
        ) !=
        1) {
      throw StateError('Resident task missing');
    }
  }

  Future<void> completeTask(String id, bool done, Day today) async {
    await db.transaction((txn) async {
      final rows = await txn.query('tasks', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) throw StateError('Task missing');
      if (rows.single['resident'] == 1) {
        throw ArgumentError('Resident task requires dated record');
      }
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

  Future<void> saveNote(Note note, {bool create = false, Day? today}) async {
    if (note.body.trim().isEmpty || note.body.length > 10000) {
      throw ArgumentError('Invalid note');
    }
    Day.parse(note.day.key);
    if (note.day.compareTo(today ?? Day(DateTime.now())) > 0) {
      throw ArgumentError('Future note date');
    }
    await db.transaction((txn) async {
      if (note.habitId != null &&
          (await txn.query(
            'habits',
            columns: ['id'],
            where: 'id=?',
            whereArgs: [note.habitId],
          )).isEmpty) {
        throw StateError('Habit missing');
      }
      if (create) {
        await txn.insert('notes', note.toMap());
      } else if (await txn.update(
            'notes',
            note.toMap(),
            where: 'id = ?',
            whereArgs: [note.id],
          ) !=
          1) {
        throw StateError('Note missing');
      }
    });
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
        {'completion_sound', 'completion_haptics'}.contains(key) &&
            !{'on', 'off'}.contains(value) ||
        !{
          'theme',
          'locale',
          'completion_sound',
          'completion_haptics',
        }.contains(key)) {
      throw ArgumentError('Invalid preference');
    }
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
