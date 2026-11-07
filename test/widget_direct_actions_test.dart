import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/habit_break.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory dir;
  final today = Day.parse('2026-11-07');
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('direct-widget-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/db',
    );
    await store.saveHabit(
      Habit(id: 'h', title: 'Reading', kind: HabitKind.check, startDay: today),
      create: true,
    );
  });
  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });
  Future<bool> set(
    bool done, {
    int? revision,
    Object? expected,
    String kind = 'habit',
    String id = 'h',
    Day? day,
    int? epoch,
  }) async => store.applyWidgetValue(
    kind: kind,
    id: id,
    day: day ?? today,
    generation: epoch ?? await store.generation(),
    revision: revision ?? await store.widgetRevision(),
    expectedValue: expected,
    completed: done,
    clock: () => today.date,
  );
  test(
    'direct completion is explicit, duplicates reject, undo keeps earned card',
    () async {
      final before = await store.widgetRevision();
      expect(await set(true, revision: before), isTrue);
      expect(await set(true, revision: before), isFalse);
      expect((await store.entries()).single.value, 1000);
      expect((await store.cards()).length, 1);
      final undo = await store.widgetRevision();
      expect(await set(false, revision: undo, expected: 1000), isTrue);
      expect(await set(false, revision: undo, expected: 1000), isFalse);
      expect(await store.entries(), isEmpty);
      expect((await store.cards()).length, 1);
    },
  );
  test('value equality cannot authorize stale undo after ABA', () async {
    await set(true);
    final old = await store.widgetRevision();
    await store.setRecord('h', today, null, today: today);
    await store.setRecord('h', today, 1000, today: today);
    expect(await set(false, revision: old, expected: 1000), isFalse);
    expect((await store.entries()).single.value, 1000);
  });
  test(
    'old completion cannot resurrect a removed record after a later completion and undo',
    () async {
      final first = await store.widgetRevision();
      await set(true);
      await set(false, expected: 1000);
      expect(await set(true, revision: first), isFalse);
      expect(await store.entries(), isEmpty);
    },
  );
  test(
    'second connection mutations and rollback preserve revision atomicity',
    () async {
      final other = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/db',
      );
      final revision = await store.widgetRevision();
      await other.setRecord('h', today, 1000, today: today);
      expect(await set(true, revision: revision), isFalse);
      final current = await store.widgetRevision();
      await expectLater(
        store.inGeneration(0, () async {
          await store.setRecord('h', today, null, today: today);
          throw StateError('rollback');
        }),
        throwsStateError,
      );
      expect(await store.widgetRevision(), current);
      expect((await store.entries()).single.value, 1000);
      await other.close();
    },
  );
  test(
    'restore and rollback never revive old generation or revision',
    () async {
      final snap = await store.exportSnapshot();
      final rev = await store.widgetRevision();
      await store.restoreSnapshot(snap);
      await expectLater(set(true, revision: rev, epoch: 0), throwsStateError);
      expect(await store.widgetRevision(), greaterThan(rev));
      final recovered = await store.recoverySnapshot();
      await store.restoreSnapshot(recovered!, rollback: true);
      await expectLater(set(true, revision: rev, epoch: 0), throwsStateError);
      expect(await store.entries(), isEmpty);
    },
  );
  test('rest archive deletion future and stale binding cannot write', () async {
    expect(await set(true, day: today.plus(-1)), isFalse);
    expect(await set(true, day: today.plus(1)), isFalse);
    expect(
      await store.applyWidgetValue(
        kind: 'habit',
        id: 'h',
        day: today,
        generation: 0,
        revision: await store.widgetRevision(),
        expectedValue: null,
        completed: true,
        clock: () => today.date,
        bindingStillValid: () async => false,
      ),
      isFalse,
    );
    await store.addBreak(
      HabitBreak(id: 'r', habitId: 'h', start: today, kind: BreakKind.pause),
      today: today,
    );
    await expectLater(set(true), throwsArgumentError);
    await store.endBreak((await store.breaks()).single, today: today);
    await store.setArchived('h', true, today: today);
    await expectLater(set(true), throwsArgumentError);
    await store.remove('habits', 'h');
    expect(await set(true), isFalse);
  });
  test(
    'quantities cannot use background completion and current-value mismatch rejects',
    () async {
      await store.saveHabit(
        Habit(
          id: 'q',
          title: 'Water',
          kind: HabitKind.quantity,
          startDay: today,
          target: 1500000,
          unit: 'ml',
        ),
        create: true,
      );
      expect(await set(true, id: 'q'), isFalse);
      expect(await set(false, expected: 1000), isFalse);
      expect(await store.entries(), isEmpty);
    },
  );
  test(
    'resident and one-time task explicit values preserve daily semantics',
    () async {
      await store.saveTask(
        SmallTask(id: 'r', title: 'Stretch', resident: true, startDay: today),
        create: true,
      );
      await store.saveTask(
        SmallTask(id: 't', title: 'Post', dueDay: today.plus(-3)),
        create: true,
      );
      final r = await store.widgetRevision();
      expect(await set(true, id: 'r', kind: 'task', revision: r), isTrue);
      expect(await set(true, id: 'r', kind: 'task', revision: r), isFalse);
      expect((await store.taskEntries()).length, 1);
      expect(
        await set(false, id: 'r', kind: 'task', expected: today.key),
        isTrue,
      );
      expect(await store.taskEntries(), isEmpty);
      expect(await set(true, id: 't', kind: 'task'), isTrue);
      expect(
        await set(false, id: 't', kind: 'task', expected: today.key),
        isTrue,
      );
      final t = (await store.tasks()).firstWhere((t) => t.id == 't');
      expect(t.dueDay, today.plus(-3));
      expect(t.completedDay, isNull);
    },
  );
  test('midnight while checking binding cannot write to the old day', () async {
    var now = today;
    expect(
      await store.applyWidgetValue(
        kind: 'habit',
        id: 'h',
        day: today,
        generation: 0,
        revision: await store.widgetRevision(),
        expectedValue: null,
        completed: true,
        clock: () => now.date,
        bindingStillValid: () async {
          now = today.plus(1);
          return true;
        },
      ),
      isFalse,
    );
    expect(await store.entries(), isEmpty);
  });
  test(
    'v9 migration preserves user rows; runtime revision is not exported or imported',
    () async {
      final before = (await store.habits()).single.toMap();
      for (final row in await store.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='trigger' AND name LIKE 'widget_%'",
      )) {
        await store.db.execute('DROP TRIGGER ${row['name']}');
      }
      await store.db.execute('ALTER TABLE runtime DROP COLUMN revision');
      await store.db.setVersion(9);
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/db',
      );
      expect(await store.db.getVersion(), 10);
      expect((await store.habits()).single.toMap(), before);
      expect(await store.widgetRevision(), 0);
      final snap = await store.exportSnapshot();
      expect(snap.tables.containsKey('runtime'), isFalse);
      final envelope = jsonDecode(utf8.decode(snap.encode())) as Map;
      final payload = jsonDecode(envelope['payload']) as Map;
      expect(payload['schema'], 10);
      payload['schema'] = 9;
      envelope['payload'] = jsonEncode(payload);
      envelope['sha256'] = sha256
          .convert(utf8.encode(envelope['payload']))
          .toString();
      await store.restoreSnapshot(
        BackupSnapshot.decode(utf8.encode(jsonEncode(envelope))),
      );
      expect(await store.widgetRevision(), greaterThan(0));
      expect((await store.habits()).single.toMap(), before);
    },
  );
}
