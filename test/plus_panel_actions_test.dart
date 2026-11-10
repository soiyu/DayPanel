import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/csv_export.dart';
import 'dart:convert';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  final day = Day.parse('2026-11-11');
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    for (final id in ['a', 'b']) {
      await store.saveHabit(
        Habit(id: id, title: id, kind: HabitKind.check, startDay: day),
        create: true,
        today: day,
      );
    }
  });
  tearDown(() async => store.close());
  Future<int> rev(String id) async =>
      (await store.db.query(
            'item_revisions',
            where: 'kind=? AND id=?',
            whereArgs: ['habit', id],
          )).single['revision']
          as int;
  Future<bool> set(
    String id,
    int r,
    bool done, {
    Object? value,
    int epoch = 0,
  }) => store.applyWidgetValue(
    kind: 'habit',
    id: id,
    day: day,
    generation: epoch,
    revision: 0,
    itemRevision: r,
    expectedValue: value,
    completed: done,
    clock: () => day.date,
  );
  test(
    'two panel rows from one rendering can complete independently',
    () async {
      final a = await rev('a'), b = await rev('b');
      expect(await set('a', a, true), isTrue);
      expect(await set('b', b, true), isTrue);
      expect((await store.entries()).length, 2);
      expect(await store.cards(), hasLength(1));
      expect(await set('a', a, true), isFalse);
      expect((await store.entries()).length, 2);
    },
  );
  test(
    'item clock survives replace, undo ABA, deletion and restoration',
    () async {
      final a = await rev('a');
      await set('a', a, true);
      final undo = await rev('a');
      await store.setRecord('a', day, null, today: day);
      await store.setRecord('a', day, 1000, today: day);
      expect(await rev('a'), greaterThan(undo));
      expect(await set('a', undo, false, value: 1000), isFalse);
      final snapshot = await store.exportSnapshot();
      expect(snapshot.tables.keys, isNot(contains('item_revisions')));
      await store.restoreSnapshot(snapshot);
      await expectLater(
        set('a', await rev('a'), false, value: 1000),
        throwsStateError,
      );
      final before = await rev('a');
      await store.remove('habits', 'a');
      await store.saveHabit(
        Habit(id: 'a', title: 'new', kind: HabitKind.check, startDay: day),
        create: true,
        today: day,
      );
      expect(await rev('a'), greaterThan(before));
    },
  );
  test('group foreign-key unlink cannot reset object clock or fail', () async {
    await store.saveGroup(
      const HabitGroup(id: 'g', name: 'Study'),
      create: true,
    );
    final h = (await store.habits()).first;
    await store.saveHabit(
      Habit.fromMap({...h.toMap(), 'group_id': 'g'}),
      today: day,
    );
    final before = await rev(h.id);
    await store.removeGroup('g');
    expect(await store.groups(), isEmpty);
    expect((await store.habits()).first.groupId, isNull);
    expect(await rev(h.id), greaterThan(before));
  });
  test(
    'CSV is readable, includes content and shields spreadsheet formulas',
    () async {
      await store.saveNote(
        Note(id: 'n', body: '=HYPERLINK("bad")\nquoted,words', day: day),
        create: true,
        today: day,
      );
      final s = await store.exportSnapshot();
      final csv = utf8.decode(readableCsv(s));
      expect(csv, contains("'=HYPERLINK"));
      expect(csv, contains('""bad""'));
      expect(csv, contains('quoted,words'));
      expect(s.tables.keys, orderedEquals(BackupSnapshot.tableNames));
    },
  );
}
