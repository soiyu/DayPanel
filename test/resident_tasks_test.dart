import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/models.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory dir;
  final first = Day.parse('2026-11-06');
  SmallTask resident() => SmallTask(
    id: 'r',
    title: 'Water the plants',
    resident: true,
    startDay: first,
  );
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('resident-tasks-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/data.db',
    );
  });
  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });
  test(
    'v3 migration preserves single tasks and completion dates without creating resident history',
    () async {
      final path = '${dir.path}/legacy.db';
      final legacy = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            // These v2 tables also exist in a real v3 database. The widget
            // mutation clock now requires them during the v10 migration.
            await db.execute(
              'CREATE TABLE runtime(id INTEGER PRIMARY KEY,generation INTEGER NOT NULL)',
            );
            await db.insert('runtime', {'id': 1, 'generation': 0});
            await db.execute(
              'CREATE TABLE plans(habit_id TEXT,effective_day TEXT,target INTEGER,unit TEXT,schedule TEXT,weekdays INTEGER,interval_days INTEGER,weekly_goal INTEGER)',
            );
            await db.execute(
              'CREATE TABLE entries(habit_id TEXT,day TEXT,value INTEGER)',
            );
            await db.execute(
              'CREATE TABLE habits(id TEXT PRIMARY KEY,start_day TEXT,archived INTEGER,kind TEXT)',
            );
            await db.execute(
              'CREATE TABLE notes(id TEXT PRIMARY KEY,body TEXT,day TEXT)',
            );
            await db.execute(
              'CREATE TABLE tasks(id TEXT PRIMARY KEY,title TEXT NOT NULL,due_day TEXT,completed_day TEXT)',
            );
            await db.insert('tasks', {
              'id': 't',
              'title': 'Old task',
              'due_day': '2026-10-10',
              'completed_day': '2026-10-09',
            });
          },
        ),
      );
      await legacy.close();
      final migrated = await AppStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      expect(await migrated.db.getVersion(), 12);
      final task = (await migrated.tasks()).single;
      expect(task.resident, isFalse);
      expect(task.startDay, isNull);
      expect(task.archived, isFalse);
      expect(task.completedDay, Day.parse('2026-10-09'));
      expect(task.dueDay, Day.parse('2026-10-10'));
      expect(await migrated.taskEntries(), isEmpty);
      await migrated.close();
    },
  );
  test(
    'resident daily completion is explicit and idempotent; gaps create no rows or debt',
    () async {
      await store.saveTask(resident(), create: true, today: first);
      await store.setResidentRecord('r', first, true, today: first);
      await store.setResidentRecord('r', first, true, today: first);
      final third = first.plus(2);
      await store.setResidentRecord('r', third, true, today: third);
      var clock = third.date;
      final app = AppController(store, clock: () => clock);
      await app.load();
      expect(app.taskEntries.length, 2);
      expect(app.taskDoneOn(resident(), first.plus(1)), isFalse);
      expect(app.tasks.single.completedDay, isNull);
      expect(app.tasks.single.dueDay, isNull);
      expect(app.taskDoneOn(resident(), third), isTrue);
      clock = third.plus(1).date;
      expect(app.taskDoneOn(resident(), app.today), isFalse);
      expect(app.residentTasks.single.id, 'r');
      expect(app.taskEntries.length, 2);
      expect(app.oneTimeTasks, isEmpty);
      app.dispose();
    },
  );
  test(
    'date correction removes only selected record and survives restart',
    () async {
      await store.saveTask(resident(), create: true, today: first);
      for (var i = 0; i < 3; i++) {
        await store.setResidentRecord(
          'r',
          first.plus(i),
          true,
          today: first.plus(2),
        );
      }
      await store.setResidentRecord(
        'r',
        first.plus(1),
        false,
        today: first.plus(2),
      );
      await store.setResidentRecord(
        'r',
        first.plus(1),
        false,
        today: first.plus(2),
      );
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/data.db',
      );
      expect((await store.taskEntries()).map((e) => e.day.key).toList(), [
        '2026-11-08',
        '2026-11-06',
      ]);
    },
  );
  test(
    'future, pre-start, wrong type and missing task reject dated writes',
    () async {
      await store.saveTask(resident(), create: true, today: first);
      await store.saveTask(
        const SmallTask(id: 'single', title: 'Book'),
        create: true,
      );
      for (final date in [first.plus(-1), first.plus(1)]) {
        await expectLater(
          store.setResidentRecord('r', date, true, today: first),
          throwsArgumentError,
        );
      }
      await expectLater(
        store.setResidentRecord('single', first, true, today: first),
        throwsArgumentError,
      );
      await expectLater(
        store.setResidentRecord('missing', first, true, today: first),
        throwsStateError,
      );
      await expectLater(
        store.completeTask('r', true, first),
        throwsArgumentError,
      );
      expect(await store.taskEntries(), isEmpty);
    },
  );
  test(
    'archive retains history; old editor cannot unarchive; deletion cascades',
    () async {
      await store.saveTask(resident(), create: true, today: first);
      await store.setResidentRecord('r', first, true, today: first);
      await store.archiveTask('r', true);
      await store.saveTask(
        SmallTask.fromMap({...resident().toMap(), 'title': 'Renamed'}),
      );
      expect((await store.tasks()).single.archived, isTrue);
      await expectLater(
        store.setResidentRecord('r', first, false, today: first),
        throwsArgumentError,
      );
      expect((await store.taskEntries()).length, 1);
      await store.archiveTask('r', false);
      await store.remove('tasks', 'r');
      expect(await store.taskEntries(), isEmpty);
      await expectLater(store.saveTask(resident()), throwsStateError);
    },
  );
  test(
    'task kinds and start dates are immutable; ordinary completion behavior unchanged',
    () async {
      await store.saveTask(resident(), create: true, today: first);
      await store.saveTask(
        SmallTask(id: 't', title: 'Once', dueDay: first.plus(3)),
        create: true,
      );
      await expectLater(
        store.saveTask(const SmallTask(id: 'r', title: 'Wrong type')),
        throwsStateError,
      );
      await expectLater(
        store.saveTask(
          SmallTask.fromMap({
            ...resident().toMap(),
            'start_day': first.plus(-1).key,
          }),
        ),
        throwsStateError,
      );
      await expectLater(
        store.saveTask(
          SmallTask(
            id: 'x',
            title: 'Invalid',
            resident: true,
            startDay: first,
            dueDay: first,
          ),
          create: true,
          today: first,
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.saveTask(
          SmallTask(
            id: 'x',
            title: 'Invalid',
            resident: true,
            startDay: first.plus(-1),
          ),
          create: true,
          today: first,
        ),
        throwsArgumentError,
      );
      await store.completeTask('t', true, first);
      await store.completeTask('t', true, first.plus(1));
      expect(
        (await store.tasks()).firstWhere((t) => t.id == 't').completedDay,
        first,
      );
      await store.completeTask('t', false, first.plus(1));
      expect(
        (await store.tasks()).firstWhere((t) => t.id == 't').dueDay,
        first.plus(3),
      );
    },
  );
  test(
    'midnight and restored generation reject stale resident actions',
    () async {
      await store.saveTask(resident(), create: true, today: first);
      var now = first.date;
      final app = AppController(store, clock: () => now);
      await app.load();
      final oldEpoch = app.generation;
      now = first.plus(1).date;
      expect(
        await app.recordResidentToday(resident(), first, true, oldEpoch),
        isFalse,
      );
      expect(app.taskEntries, isEmpty);
      final snapshot = await store.exportSnapshot();
      await app.run(() => store.restoreSnapshot(snapshot));
      expect(
        await app.recordResidentToday(resident(), app.today, true, oldEpoch),
        isFalse,
      );
      expect(app.taskEntries, isEmpty);
      app.dispose();
    },
  );
  test(
    'backup and recovery preserve resident fields and dated history, invalid references fail',
    () async {
      await store.saveTask(resident(), create: true, today: first);
      await store.setResidentRecord('r', first, true, today: first);
      final backup = await store.exportSnapshot();
      expect(backup.count('task_entries'), 1);
      await store.archiveTask('r', true);
      await store.restoreSnapshot(backup);
      expect((await store.tasks()).single.archived, isFalse);
      expect((await store.taskEntries()).single.day, first);
      await store.restoreSnapshot(
        (await store.recoverySnapshot())!,
        rollback: true,
      );
      expect((await store.tasks()).single.archived, isTrue);
      expect((await store.taskEntries()).length, 1);
      for (final mutate in <void Function(Map)>[
        (p) => p['tables']['task_entries'][0]['task_id'] = 'missing',
        (p) => p['tables']['task_entries'][0]['day'] = '2026-11-05',
        (p) => p['tables']['task_entries'].add(p['tables']['task_entries'][0]),
        (p) => p['tables']['tasks'][0]['due_day'] = '2026-11-06',
        (p) => p['tables']['tasks'][0]['completed_day'] = '2026-11-06',
        (p) => p['tables']['tasks'][0]['resident'] = 0,
        (p) => p['tables']['tasks'][0]['start_day'] = null,
      ]) {
        final e = jsonDecode(utf8.decode(backup.encode())) as Map;
        final p = jsonDecode(e['payload'] as String) as Map;
        mutate(p);
        e['payload'] = jsonEncode(p);
        e['sha256'] = sha256
            .convert(utf8.encode(e['payload'] as String))
            .toString();
        expect(
          () => BackupSnapshot.decode(utf8.encode(jsonEncode(e))),
          throwsA(isA<BackupInvalid>()),
        );
      }
    },
  );
  for (final schema in [2, 3]) {
    test(
      'schema $schema backup restores as one-time data and rollback recovers resident tasks',
      () async {
        await store.saveTask(
          const SmallTask(id: 't', title: 'Existing once'),
          create: true,
        );
        final base = await store.exportSnapshot();
        final e = jsonDecode(utf8.decode(base.encode())) as Map;
        final p = jsonDecode(e['payload'] as String) as Map;
        p['schema'] = schema;
        (p['tables'] as Map).remove('record_events');
        (p['tables'] as Map).remove('habit_breaks');
        for (final h in p['tables']['habits'] as List) {
          (h as Map).remove('color');
          h.remove('frame');
        }
        (p['tables'] as Map).remove('cards');
        (p['tables'] as Map).remove('habit_activity');
        (p['tables'] as Map).remove('task_entries');
        if (schema == 2) (p['tables'] as Map).remove('reminders');
        for (final row in p['tables']['tasks'] as List) {
          (row as Map).removeWhere(
            (k, v) => {'resident', 'start_day', 'archived'}.contains(k),
          );
        }
        e['payload'] = jsonEncode(p);
        e['sha256'] = sha256
            .convert(utf8.encode(e['payload'] as String))
            .toString();
        await store.saveTask(resident(), create: true, today: first);
        await store.setResidentRecord('r', first, true, today: first);
        await store.restoreSnapshot(
          BackupSnapshot.decode(utf8.encode(jsonEncode(e))),
        );
        expect((await store.tasks()).single.resident, isFalse);
        expect(await store.taskEntries(), isEmpty);
        await store.restoreSnapshot(
          (await store.recoverySnapshot())!,
          rollback: true,
        );
        expect((await store.tasks()).length, 2);
        expect((await store.taskEntries()).single.taskId, 'r');
      },
    );
  }
  test(
    'completed task totals include both types but never affect habit records',
    () async {
      await store.saveTask(resident(), create: true, today: first);
      await store.saveTask(
        const SmallTask(id: 't', title: 'Once'),
        create: true,
      );
      await store.setResidentRecord('r', first, true, today: first);
      await store.completeTask('t', true, first);
      final app = AppController(store, clock: () => first.date);
      await app.load();
      expect(app.tasksCompletedOn(first), 2);
      expect(app.entries, isEmpty);
      expect(app.completed, 0);
      app.dispose();
    },
  );
}
