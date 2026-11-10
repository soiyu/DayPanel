import 'schema_fixture.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/statistics.dart';

void main() {
  sqfliteFfiInit();
  final today = Day.parse('2026-11-08');
  late AppStore store;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() => store.close());
  Habit count({int target = 3000, String unit = 'times'}) => Habit(
    id: 'c',
    title: 'Practice',
    kind: HabitKind.count,
    startDay: today.plus(-6),
    target: target,
    unit: unit,
  );
  Future<void> createCount() =>
      store.saveHabit(count(), create: true, today: today);
  List<int> altered(
    BackupSnapshot snapshot,
    void Function(Map<String, dynamic>) mutate,
  ) {
    final envelope =
        jsonDecode(utf8.decode(snapshot.encode())) as Map<String, dynamic>;
    final payload =
        jsonDecode(envelope['payload'] as String) as Map<String, dynamic>;
    mutate(payload);
    envelope['payload'] = jsonEncode(payload);
    envelope['sha256'] = sha256
        .convert(utf8.encode(envelope['payload'] as String))
        .toString();
    return utf8.encode(jsonEncode(envelope));
  }

  test(
    'count enforces whole targets and daily values without rewriting quantity',
    () async {
      await expectLater(
        store.saveHabit(count(target: 1500), create: true),
        throwsArgumentError,
      );
      await createCount();
      await expectLater(
        store.setRecord('c', today, 1500, today: today),
        throwsArgumentError,
      );
      await store.setRecord('c', today, 0, today: today);
      expect((await store.entries()).single.value, 0);
      await store.setRecord('c', today, 3000, today: today);
      expect((await store.entries()).single.value, 3000);
      await store.saveHabit(
        Habit(
          id: 'q',
          title: 'Existing quantity',
          kind: HabitKind.quantity,
          startDay: today,
          target: 1500,
          unit: 'times',
        ),
        create: true,
      );
      await store.setRecord('q', today, 1250, today: today);
      expect(
        (await store.entries()).singleWhere((e) => e.habitId == 'q').value,
        1250,
      );
    },
  );

  test(
    'count plan changes start tomorrow and statistics keep historical units',
    () async {
      await createCount();
      await store.setRecord('c', today, 3000, today: today);
      await store.saveHabit(count(target: 4000, unit: 'sets'), today: today);
      await expectLater(
        store.saveHabit(count(target: 4500), today: today),
        throwsArgumentError,
      );
      final h = (await store.habits()).single;
      final stats = HabitStatistics(
        h,
        await store.plans(),
        await store.activity(),
        await store.entries(),
        today,
      );
      expect(stats.plan(today).target, 3000);
      expect(stats.plan(today.plus(1)).target, 4000);
      expect(stats.quantities(today, today)['times']!.single.value, 3000);
      expect(stats.quantities(today, today).containsKey('sets'), isFalse);
    },
  );

  test(
    'count earns a card only at today threshold and card remains after deletion',
    () async {
      await createCount();
      await store.setRecord('c', today.plus(-1), 3000, today: today);
      expect(await store.cards(), isEmpty);
      await store.setRecord('c', today, 2000, today: today);
      expect(await store.cards(), isEmpty);
      await store.setRecord('c', today, 3000, today: today);
      final cards = await store.cards();
      expect(cards.single.evidence.single.kind, HabitKind.count);
      await store.remove('habits', 'c');
      expect((await store.cards()).single.evidence.single.value, 3000);
      final snapshot = await store.exportSnapshot();
      expect(BackupSnapshot.decode(snapshot.encode()).count('cards'), 1);
      expect(
        () => BackupSnapshot.decode(
          altered(snapshot, (p) {
            p['schema'] = 10;
            (p['tables'] as Map).remove('record_events');
          }),
        ),
        throwsA(isA<BackupInvalid>()),
      );
    },
  );

  test(
    'schema eleven count backup restores and rollback preserves whole facts',
    () async {
      await createCount();
      await store.setRecord('c', today, 1000, today: today);
      final snapshot = await store.exportSnapshot();
      final envelope = jsonDecode(utf8.decode(snapshot.encode())) as Map;
      expect(jsonDecode(envelope['payload'])['schema'], 12);
      await store.setRecord('c', today, 2000, today: today);
      await store.restoreSnapshot(BackupSnapshot.decode(snapshot.encode()));
      expect((await store.entries()).single.value, 1000);
      await store.restoreSnapshot(
        (await store.recoverySnapshot())!,
        rollback: true,
      );
      expect((await store.entries()).single.value, 2000);
      expect((await store.habits()).single.kind, HabitKind.count);
    },
  );

  test(
    'backup rejects fractional count target plan value and earned evidence',
    () async {
      await createCount();
      await store.setRecord('c', today, 3000, today: today);
      final snapshot = await store.exportSnapshot();
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (p) => p['tables']['habits'][0]['target'] = 1500,
        (p) => p['tables']['plans'][0]['target'] = 1500,
        (p) => p['tables']['entries'][0]['value'] = 1500,
        (p) {
          final evidence =
              jsonDecode(p['tables']['cards'][0]['evidence']) as List;
          evidence[0]['value'] = 3500;
          p['tables']['cards'][0]['evidence'] = jsonEncode(evidence);
        },
        (p) {
          final evidence =
              jsonDecode(p['tables']['cards'][0]['evidence']) as List;
          evidence[0]['target'] = 1500;
          p['tables']['cards'][0]['evidence'] = jsonEncode(evidence);
        },
      ]) {
        expect(
          () => BackupSnapshot.decode(altered(snapshot, mutate)),
          throwsA(isA<BackupInvalid>()),
        );
      }
      expect((await store.entries()).single.value, 3000);
    },
  );

  test('older backup schemas cannot smuggle new count enum', () async {
    await createCount();
    final snapshot = await store.exportSnapshot();
    for (var schema = 2; schema <= 10; schema++) {
      expect(
        () => BackupSnapshot.decode(
          altered(snapshot, (p) {
            p['schema'] = schema;
            (p['tables'] as Map).remove('record_events');
          }),
        ),
        throwsA(isA<BackupInvalid>()),
      );
    }
  });

  test(
    'schema ten quantity with times unit keeps fractional values unchanged',
    () async {
      await store.saveHabit(
        Habit(
          id: 'q',
          title: 'Old times',
          kind: HabitKind.quantity,
          startDay: today,
          target: 1500,
          unit: 'times',
        ),
        create: true,
      );
      await store.setRecord('q', today, 1250, today: today);
      final old = altered(await store.exportSnapshot(), (p) {
        p['schema'] = 10;
        (p['tables'] as Map).remove('record_events');
      });
      await store.restoreSnapshot(BackupSnapshot.decode(old));
      expect((await store.habits()).single.kind, HabitKind.quantity);
      expect((await store.entries()).single.value, 1250);
    },
  );

  test(
    'revision guarded submission cannot be replayed or overwrite ABA',
    () async {
      await createCount();
      await store.setRecord('c', today, 1000, today: today);
      final revision = await store.revision();
      await store.inGeneration(
        await store.generation(),
        () => store.setRecord(
          'c',
          today,
          2000,
          today: today,
          expectedRevision: revision,
        ),
      );
      await expectLater(
        store.setRecord(
          'c',
          today,
          2000,
          today: today,
          expectedRevision: revision,
        ),
        throwsA(isA<RecordRevisionConflict>()),
      );
      await store.setRecord('c', today, 1000, today: today);
      await expectLater(
        store.setRecord(
          'c',
          today,
          3000,
          today: today,
          expectedRevision: revision,
        ),
        throwsA(isA<RecordRevisionConflict>()),
      );
      expect((await store.entries()).single.value, 1000);
      expect(await store.cards(), isEmpty);
    },
  );

  test(
    'controller reloads after conflict and old generation cannot write after restore',
    () async {
      await createCount();
      final app = AppController(store, clock: () => today.date);
      addTearDown(app.dispose);
      await app.load();
      final revision = app.revision;
      final epoch = app.generation;
      await store.setRecord('c', today, 1000, today: today);
      expect(
        await app.recordHabit(
          count(),
          today,
          2000,
          epoch,
          expectedRevision: revision,
        ),
        isFalse,
      );
      expect(app.error, 'record_conflict');
      expect(app.value(count(), today), 1000);
      expect(app.revision, await store.revision());
      final snapshot = await store.exportSnapshot();
      await store.restoreSnapshot(snapshot);
      expect(
        await app.recordHabit(
          count(),
          today,
          3000,
          epoch,
          expectedRevision: app.revision,
        ),
        isFalse,
      );
      expect((await store.entries()).single.value, 1000);
    },
  );

  test(
    'two independent connections cannot both commit one captured total',
    () async {
      final dir = await Directory.systemTemp.createTemp('count-concurrent-');
      AppStore? first;
      AppStore? second;
      try {
        final path = '${dir.path}/data.db';
        first = await AppStore.open(factory: databaseFactoryFfi, path: path);
        second = await AppStore.open(factory: databaseFactoryFfi, path: path);
        await first.saveHabit(count(), create: true, today: today);
        final expected = await first.revision();
        final epoch = await first.generation();
        Future<bool> commit(AppStore target, int value) async {
          try {
            await target.inGeneration(
              epoch,
              () => target.setRecord(
                'c',
                today,
                value,
                today: today,
                expectedRevision: expected,
              ),
            );
            return true;
          } on RecordRevisionConflict {
            return false;
          } on DatabaseException catch (error) {
            // Separate ffi handles can reject a concurrent BEGIN as SQLITE_BUSY.
            // The app also fails that write; retry still needs the original CAS.
            if (error.toString().contains('database is locked')) return false;
            rethrow;
          }
        }

        final outcomes = await Future.wait([
          commit(first, 1000),
          commit(second, 2000),
        ]);
        expect(outcomes.where((ok) => ok).length, 1);
        expect([1000, 2000], contains((await first.entries()).single.value));
        expect(await first.revision(), greaterThan(expected));
        final committedRevision = await first.revision();
        await expectLater(
          second.inGeneration(
            epoch,
            () => second!.setRecord(
              'c',
              today,
              3000,
              today: today,
              expectedRevision: expected,
            ),
          ),
          throwsA(isA<RecordRevisionConflict>()),
        );
        expect(await first.revision(), committedRevision);
      } finally {
        await first?.close();
        await second?.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'count never takes the boolean background widget completion path',
    () async {
      await createCount();
      expect(
        await store.applyWidgetValue(
          kind: 'habit',
          id: 'c',
          day: today,
          generation: await store.generation(),
          revision: await store.revision(),
          expectedValue: null,
          completed: true,
          clock: () => today.date,
        ),
        isFalse,
      );
      expect(await store.entries(), isEmpty);
    },
  );

  test(
    'schema ten migration preserves prior tables and runtime while adding event baselines',
    () async {
      final dir = await Directory.systemTemp.createTemp('count-migration-');
      AppStore? fileStore;
      try {
        fileStore = await AppStore.open(
          factory: databaseFactoryFfiNoIsolate,
          path: '${dir.path}/data.db',
        );
        await fileStore.saveHabit(
          Habit(
            id: 'q',
            title: 'Old quantity',
            kind: HabitKind.quantity,
            startDay: today,
            target: 1500,
            unit: 'times',
          ),
          create: true,
        );
        await fileStore.setRecord('q', today, 1250, today: today);
        final tables = <String, List<Map<String, Object?>>>{};
        for (final table in [
          ...BackupSnapshot.tableNames.where((name) => name != 'record_events'),
          'runtime',
          'recovery',
        ]) {
          tables[table] = await fileStore.db.query(table, orderBy: 'rowid');
        }
        await discardV12Fixture(fileStore.db);
        await fileStore.db.setVersion(10);
        await fileStore.close();
        fileStore = await AppStore.open(
          factory: databaseFactoryFfiNoIsolate,
          path: '${dir.path}/data.db',
        );
        expect(await fileStore.db.getVersion(), 12);
        for (final table in tables.keys) {
          expect(
            await fileStore.db.query(table, orderBy: 'rowid'),
            tables[table],
            reason: table,
          );
        }
      } finally {
        await fileStore?.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
