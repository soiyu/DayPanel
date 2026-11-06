import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/legacy_import.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/statistics.dart';
import 'support/legacy_fixture.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  final day = Day.parse('2026-11-06');
  LegacyImport read([Map<Object?, Object?>? raw]) =>
      LegacyImport.decode(raw ?? legacyFixture(), today: day);
  Map<String, LegacySchedule> choices(LegacyImport data) => {
    for (final h in data.habits)
      h.id: const LegacySchedule(ScheduleKind.weekdays),
  };
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() async {
    await store.close();
  });
  test(
    'original check statuses differ from tiny quantities and UTC dates stay exact',
    () {
      final data = read();
      final h = data.habits.first;
      expect(h.records, 2);
      expect(h.skipped, 1);
      expect(h.ignored, 2);
      expect(h.entries.first.value, 1000);
      expect(h.entries[1].value, 0);
      expect(h.entries.first.day.key, '2026-11-01');
      final raw = legacyFixture();
      final es = raw['entries'] as List;
      es.removeWhere((e) => e['habit'] == 2);
      for (var n = 0; n < 4; n++) {
        es.add({
          'habit': 2,
          'timestamp': DateTime.utc(2026, 11, n + 1).millisecondsSinceEpoch,
          'value': n,
          'notes': '',
        });
      }
      expect(read(raw).habits.last.entries.map((e) => e.value), [0, 1, 2, 3]);
    },
  );
  test(
    'target conversion is exact and refuses rounding zero overflow and special values',
    () {
      expect(LegacyImport.targetThousandths('250.001'), 250001);
      expect(LegacyImport.targetThousandths('1.0e-3'), 1);
      expect(LegacyImport.targetThousandths('999999999.999'), 999999999999);
      for (final s in [
        '0',
        '-1',
        'NaN',
        'Infinity',
        '0.0001',
        '1000000000',
        '1e99',
      ]) {
        expect(LegacyImport.targetThousandths(s), isNull);
      }
    },
  );
  for (final version in [21, 22, 23, 24, 25]) {
    test(
      'supported logical format $version yields stable namespaced identity',
      () {
        final a = read(legacyFixture(version: version));
        final b = read(legacyFixture(version: version));
        expect(a.habits.map((h) => h.id), b.habits.map((h) => h.id));
        expect(a.habits.first.name, 'Old reading');
      },
    );
  }
  test(
    'archive flag and order survive while UUID avoids collisions with current numeric IDs',
    () async {
      final raw = legacyFixture();
      (raw['habits'] as List)[1]['archived'] = 1;
      await store.saveHabit(
        Habit(id: '1', title: 'Current', kind: HabitKind.check, startDay: day),
        create: true,
      );
      final data = read(raw);
      await store.importLegacy(data, choices(data), today: day, chinese: false);
      final hs = await store.habits();
      expect(hs.map((h) => h.title), ['Current', 'Old reading', 'Old water']);
      expect(hs.last.archived, isTrue);
    },
  );
  test(
    'append preserves all existing facts, gives full rollback and never earns cards',
    () async {
      await store.saveTask(
        const SmallTask(id: 't', title: 'Keep'),
        create: true,
      );
      await store.saveNote(
        Note(id: 'n', body: 'Keep journal', day: day),
        create: true,
      );
      await store.preference('font', 'serif');
      final before = await store.exportSnapshot();
      final data = read();
      await store.importLegacy(data, choices(data), today: day, chinese: true);
      expect((await store.recoverySnapshot())!.tables, before.tables);
      expect(await store.generation(), 1);
      expect((await store.tasks()).single.title, 'Keep');
      expect((await store.settings())['font'], 'serif');
      expect((await store.entries()).length, 4);
      expect(await store.cards(), isEmpty);
      expect(await store.reminders(), isEmpty);
      expect((await store.notes()).any((n) => n.body.contains('已跳过')), isTrue);
      expect(
        (await store.notes()).any((n) => n.body.contains('A small glass')),
        isTrue,
      );
      await store.restoreSnapshot(
        (await store.recoverySnapshot())!,
        rollback: true,
      );
      expect((await store.exportSnapshot()).tables, before.tables);
      expect(await store.generation(), 2);
    },
  );
  test(
    'unknown history is not failed, interval starts on import day, weekly does not become daily',
    () async {
      final data = read(legacyFixture(rolling: true));
      await store.importLegacy(
        data,
        {data.habits.first.id: const LegacySchedule(ScheduleKind.interval, 3)},
        today: day,
        chinese: false,
      );
      final h = (await store.habits()).single;
      final stats = HabitStatistics(
        h,
        await store.plans(),
        await store.activity(),
        await store.entries(),
        day,
      );
      expect(stats.state(day.plus(-1)), DayPlanState.unknown);
      expect(stats.daily(day.plus(-10), day).due, 0);
      expect(stats.plan(day).scheduled(day), isTrue);
      expect(stats.plan(day).scheduled(day.plus(1)), isFalse);
      await store.restoreSnapshot(
        (await store.recoverySnapshot())!,
        rollback: true,
      );
      await store.importLegacy(
        data,
        {data.habits.first.id: const LegacySchedule(ScheduleKind.weekly, 2)},
        today: day,
        chinese: false,
      );
      expect((await store.habits()).single.schedule, ScheduleKind.weekly);
    },
  );
  test(
    'reimport skips changed existing identities and does not replace recovery or records',
    () async {
      final data = read();
      await store.importLegacy(data, choices(data), today: day, chinese: false);
      final h = (await store.habits()).first;
      await store.saveHabit(Habit.fromMap({...h.toMap(), 'title': 'Renamed'}));
      final before = await store.exportSnapshot();
      final recovery = (await store.recoverySnapshot())!.tables;
      await expectLater(
        store.importLegacy(data, choices(data), today: day, chinese: false),
        throwsA(isA<LegacyInvalid>()),
      );
      expect((await store.exportSnapshot()).tables, before.tables);
      expect((await store.recoverySnapshot())!.tables, recovery);
      await store.remove('habits', h.id);
      await store.importLegacy(
        data,
        {h.id: const LegacySchedule(ScheduleKind.weekdays)},
        today: day,
        chinese: false,
      );
      expect((await store.habits()).length, 2);
      expect(
        (await store.notes()).map((n) => n.id).toSet().length,
        (await store.notes()).length,
      );
    },
  );
  test(
    'unsupported targets visible but cannot enter commit, valid subset can import',
    () async {
      final raw = legacyFixture();
      (raw['habits'] as List)[1]['target_type'] = 1;
      final data = read(raw);
      expect(data.habits.last.unsupported, 'atMost');
      await expectLater(
        store.importLegacy(data, choices(data), today: day, chinese: false),
        throwsA(isA<LegacyInvalid>()),
      );
      expect(await store.habits(), isEmpty);
      await store.importLegacy(
        data,
        {data.habits.first.id: const LegacySchedule(ScheduleKind.weekdays)},
        today: day,
        chinese: false,
      );
      expect((await store.habits()).length, 1);
    },
  );
  test(
    'malformed references values dates duplicates and unsupported versions reject whole input',
    () {
      for (final mutate in <void Function(Map)>[
        (r) => r['version'] = 26,
        (r) => r['entries'][0]['habit'] = 99,
        (r) => r['entries'][0]['value'] = 4,
        (r) => r['entries'][0]['timestamp'] += 1,
        (r) => r['entries'][0]['timestamp'] = DateTime.utc(
          2027,
        ).millisecondsSinceEpoch,
        (r) => r['entries'].add(r['entries'][0]),
        (r) => r['habits'].add(r['habits'][0]),
        (r) => r['habits'][1]['uuid'] = r['habits'][0]['uuid'],
        (r) => r['entries'][0]['notes'] = 123,
        (r) => r['habits'][0]['numerator'] = 10,
        (r) => r['habits'][0]['type'] = 4,
      ]) {
        final raw = jsonDecode(jsonEncode(legacyFixture())) as Map;
        mutate(raw);
        expect(
          () => read(raw.cast<Object?, Object?>()),
          throwsA(isA<LegacyInvalid>()),
        );
      }
    },
  );
  test('old preview cannot commit after restore or midnight', () async {
    final data = read();
    final app = AppController(store, clock: () => day.date);
    await app.load();
    final backup = await store.exportSnapshot();
    await app.run(() => store.restoreSnapshot(backup));
    expect(
      await app.run(
        () =>
            store.importLegacy(data, choices(data), today: day, chinese: false),
        expectedGeneration: 0,
      ),
      isFalse,
    );
    await expectLater(
      store.importLegacy(
        data,
        choices(data),
        today: day.plus(1),
        chinese: false,
      ),
      throwsA(isA<LegacyInvalid>()),
    );
    expect(await store.habits(), isEmpty);
    app.dispose();
  });
  for (final phase in ['cleared', 'inserted', 'before_commit']) {
    test(
      'import fault at $phase rolls back content generation and previous recovery',
      () async {
        await store.saveTask(
          const SmallTask(id: 'keep', title: 'Keep'),
          create: true,
        );
        final before = await store.exportSnapshot();
        final data = read();
        await expectLater(
          store.importLegacy(
            data,
            choices(data),
            today: day,
            chinese: false,
            fault: (step) async {
              if (step == phase) throw StateError('Injected');
            },
          ),
          throwsStateError,
        );
        expect((await store.exportSnapshot()).tables, before.tables);
        expect(await store.generation(), 0);
        expect(await store.recoverySnapshot(), isNull);
      },
    );
  }
}
