import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/schema.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/journal.dart';
import 'package:daypanel/domain/models.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory dir;
  final today = Day.parse('2026-11-06');
  Habit habit(String id) =>
      Habit(id: id, title: 'Reading', kind: HabitKind.check, startDay: today);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('daypanel-journal-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/data.db',
    );
    await store.saveHabit(habit('h'), create: true);
  });
  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });
  List<int> transform(BackupSnapshot snapshot, void Function(Map) change) {
    final envelope = jsonDecode(utf8.decode(snapshot.encode())) as Map;
    final payload = jsonDecode(envelope['payload'] as String) as Map;
    change(payload);
    envelope['payload'] = jsonEncode(payload);
    envelope['sha256'] = sha256
        .convert(utf8.encode(envelope['payload'] as String))
        .toString();
    return utf8.encode(jsonEncode(envelope));
  }

  test(
    'month day habit and literal body query intersect; ordering is deterministic',
    () {
      final notes = [
        Note(id: 'a', body: 'Morning TEA 100%_ 好心情', day: today, habitId: 'h'),
        Note(id: 'b', body: 'Morning tea', day: today.plus(-1)),
        Note(
          id: 'c',
          body: 'Tea in October',
          day: Day.parse('2026-10-31'),
          habitId: 'h',
        ),
        Note(id: 'd', body: 'No match', day: today, habitId: 'h'),
      ];
      expect(
        JournalQuery(
          month: today,
          habitId: 'h',
          text: ' TEA ',
        ).apply(notes).map((n) => n.id),
        ['a'],
      );
      expect(
        const JournalQuery(
          habitId: 'h',
          text: 'tea',
        ).apply(notes).map((n) => n.id),
        ['a', 'c'],
      );
      expect(
        JournalQuery(
          month: today,
          day: today.plus(-1),
          text: 'tea',
        ).apply(notes).single.id,
        'b',
      );
      expect(const JournalQuery(independent: true).apply(notes).single.id, 'b');
      expect(const JournalQuery(text: '%_').apply(notes).single.id, 'a');
      expect(const JournalQuery(text: '好心情').apply(notes).single.id, 'a');
      expect(const JournalQuery(text: 'Reading').apply(notes), isEmpty);
      expect(const JournalQuery().apply(notes).map((n) => n.id), [
        'd',
        'a',
        'b',
        'c',
      ]);
    },
  );
  test(
    'dated linked note edits and unlinking survive close reopen without completion',
    () async {
      await store.saveNote(
        Note(id: 'n', body: 'A first page', day: today, habitId: 'h'),
        create: true,
        today: today,
      );
      await store.saveNote(
        Note(
          id: 'n',
          body: 'Earlier memory',
          day: today.plus(-20),
          habitId: 'h',
        ),
        today: today,
      );
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/data.db',
      );
      final note = (await store.notes()).single;
      expect(note.body, 'Earlier memory');
      expect(note.day, today.plus(-20));
      expect(note.habitId, 'h');
      expect(await store.entries(), isEmpty);
      await store.saveNote(
        Note(id: note.id, body: note.body, day: note.day),
        today: today,
      );
      expect((await store.notes()).single.habitId, isNull);
    },
  );
  test(
    'archive keeps editable associations; delete habit retains text and date',
    () async {
      await store.saveNote(
        Note(id: 'n', body: 'Keep every word 🌱', day: today, habitId: 'h'),
        create: true,
        today: today,
      );
      await store.setArchived('h', true);
      expect((await store.notes()).single.habitId, 'h');
      await store.saveNote(
        Note(id: 'n', body: 'Updated while archived', day: today, habitId: 'h'),
        today: today,
      );
      await store.remove('habits', 'h');
      final note = (await store.notes()).single;
      expect(note.habitId, isNull);
      expect(note.body, 'Updated while archived');
      expect(note.day, today);
      expect(await store.db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect((await store.exportSnapshot()).count('notes'), 1);
    },
  );
  test(
    'invalid body date and missing references are rejected without partial changes',
    () async {
      for (final note in [
        Note(id: 'n', body: ' ', day: today),
        Note(id: 'n', body: 'x' * 10001, day: today),
        Note(id: 'n', body: 'Future', day: today.plus(1)),
      ]) {
        await expectLater(
          store.saveNote(note, create: true, today: today),
          throwsArgumentError,
        );
      }
      await expectLater(
        store.saveNote(
          Note(id: 'n', body: 'Missing', day: today, habitId: 'gone'),
          create: true,
          today: today,
        ),
        throwsStateError,
      );
      expect(await store.notes(), isEmpty);
    },
  );
  test(
    'restoring invalidates stale edit/delete and refresh drops deleted habit filter',
    () async {
      await store.saveNote(
        Note(id: 'n', body: 'Original', day: today, habitId: 'h'),
        create: true,
        today: today,
      );
      final snapshot = await store.exportSnapshot();
      final app = AppController(store, clock: () => today.date);
      await app.load();
      app.filterNotes(JournalQuery(habitId: 'h', month: today));
      final epoch = app.generation;
      await app.run(() => store.restoreSnapshot(snapshot));
      expect(
        await app.run(
          () => store.remove('notes', 'n'),
          expectedGeneration: epoch,
        ),
        isFalse,
      );
      expect(
        await app.run(
          () => store.saveNote(
            Note(id: 'n', body: 'Stale', day: today),
            today: today,
          ),
          expectedGeneration: epoch,
        ),
        isFalse,
      );
      expect((await store.notes()).single.body, 'Original');
      await app.run(() => store.remove('habits', 'h'));
      expect(app.journalQuery.habitId, isNull);
      expect(app.visibleNotes.single.body, 'Original');
      app.dispose();
    },
  );
  test(
    'schema5 restores links and rollback retains newer notes; invalid fields and references fail',
    () async {
      await store.saveNote(
        Note(id: 'n', body: 'Saved', day: today, habitId: 'h'),
        create: true,
        today: today,
      );
      final snapshot = await store.exportSnapshot();
      await store.saveNote(
        Note(id: 'n', body: 'Newer', day: today),
        today: today,
      );
      await store.restoreSnapshot(BackupSnapshot.decode(snapshot.encode()));
      expect((await store.notes()).single.habitId, 'h');
      await store.restoreSnapshot(
        (await store.recoverySnapshot())!,
        rollback: true,
      );
      expect((await store.notes()).single.body, 'Newer');
      expect((await store.notes()).single.habitId, isNull);
      for (final change in <void Function(Map)>[
        (p) => p['tables']['notes'][0]['habit_id'] = 'missing',
        (p) => p['tables']['notes'][0]['habit_id'] = 42,
        (p) => (p['tables']['notes'][0] as Map).remove('habit_id'),
        (p) => p['tables']['notes'][0]['extra'] = 'no',
        (p) => p['tables']['notes'][0]['day'] = '2026-02-30',
        (p) => (p['tables']['notes'] as List).add(p['tables']['notes'][0]),
      ]) {
        expect(
          () => BackupSnapshot.decode(transform(snapshot, change)),
          throwsA(isA<BackupInvalid>()),
        );
      }
    },
  );
  for (final version in [2, 3, 4]) {
    test(
      'schema$version backup and stored recovery copy migrate notes without losing text',
      () async {
        await store.saveNote(
          Note(id: 'n', body: 'Legacy memory', day: today),
          create: true,
          today: today,
        );
        final snapshot = await store.exportSnapshot();
        final bytes = transform(snapshot, (p) {
          p['schema'] = version;
          (p['tables'] as Map).remove('record_events');
          (p['tables'] as Map).remove('habit_breaks');
          for (final h in p['tables']['habits'] as List) {
            (h as Map).remove('color');
            h.remove('frame');
          }
          (p['tables'] as Map).remove('cards');
          (p['tables'] as Map).remove('habit_activity');
          for (final row in p['tables']['notes'] as List) {
            (row as Map).remove('habit_id');
          }
          if (version < 3) (p['tables'] as Map).remove('reminders');
          if (version < 4) (p['tables'] as Map).remove('task_entries');
        });
        await store.saveNote(
          Note(id: 'n', body: 'Current link', day: today, habitId: 'h'),
          today: today,
        );
        await store.restoreSnapshot(BackupSnapshot.decode(bytes));
        expect((await store.notes()).single.body, 'Legacy memory');
        expect((await store.notes()).single.habitId, isNull);
        await store.restoreSnapshot(
          (await store.recoverySnapshot())!,
          rollback: true,
        );
        expect((await store.notes()).single.habitId, 'h');
        await store.db.insert('recovery', {
          'id': 1,
          'snapshot': utf8.decode(bytes),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await store.restoreSnapshot(
          (await store.recoverySnapshot())!,
          rollback: true,
        );
        expect((await store.notes()).single.body, 'Legacy memory');
      },
    );
  }
  for (final version in [1, 2, 3, 4]) {
    test(
      'SQLite v$version migrates note identity text date and all existing rows',
      () async {
        final path = '${dir.path}/legacy$version.db';
        final legacy = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: version,
            onCreate: (db, _) async {
              await db.execute(
                'CREATE TABLE habits(id TEXT PRIMARY KEY,title TEXT,kind TEXT,start_day TEXT,target INTEGER,unit TEXT,weekdays INTEGER,icon INTEGER,archived INTEGER)',
              );
              await db.execute(
                'CREATE TABLE entries(habit_id TEXT,day TEXT,value INTEGER,PRIMARY KEY(habit_id,day))',
              );
              await db.execute(
                'CREATE TABLE tasks(id TEXT PRIMARY KEY,title TEXT,due_day TEXT,completed_day TEXT)',
              );
              await db.execute(
                'CREATE TABLE notes(id TEXT PRIMARY KEY,body TEXT NOT NULL,day TEXT NOT NULL)',
              );
              await db.execute(
                'CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT)',
              );
              await db.insert('notes', {
                'id': 'old',
                'body': '原始手记 🌙',
                'day': '2025-12-31',
              });
              if (version >= 2) await upgradeToV2(db);
              if (version >= 3) await upgradeToV3(db);
              if (version >= 4) await upgradeToV4(db);
            },
          ),
        );
        await legacy.close();
        final migrated = await AppStore.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        expect(await migrated.db.getVersion(), 12);
        expect((await migrated.notes()).single.toMap(), {
          'id': 'old',
          'body': '原始手记 🌙',
          'day': '2025-12-31',
          'habit_id': null,
        });
        expect((await migrated.exportSnapshot()).count('notes'), 1);
        await migrated.close();
      },
    );
  }
}
