import 'schema_fixture.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/habit_break.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/statistics.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory dir;
  final today = Day.parse('2026-11-07');
  Habit h(String id, {bool weekly = false}) => Habit(
    id: id,
    title: id,
    kind: HabitKind.check,
    startDay: today.plus(-35),
    schedule: weekly ? ScheduleKind.weekly : ScheduleKind.weekdays,
    weeklyGoal: 1,
  );
  HabitBreak rest(
    String id,
    String habit,
    Day start, {
    Day? end,
    BreakKind kind = BreakKind.pause,
  }) => HabitBreak(id: id, habitId: habit, start: start, end: end, kind: kind);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rest-test-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/db',
    );
    await store.saveHabit(h('h'), create: true);
  });
  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });
  Future<HabitStatistics> stats(String id, Day now) async => HabitStatistics(
    (await store.habits()).firstWhere((h) => h.id == id),
    await store.plans(),
    await store.activity(),
    await store.entries(),
    now,
    breaks: await store.breaks(),
  );
  test(
    'pause preserves records and plans, blocks stale records, resumes with history retained',
    () async {
      await store.setRecord('h', today.plus(-1), 1000, today: today);
      final plans = (await store.plans()).map((p) => p.toMap()).toList();
      final b = rest('p', 'h', today);
      await store.addBreak(b, today: today);
      await store.addBreak(b, today: today);
      expect((await store.breaks()).length, 1);
      await expectLater(
        store.setRecord('h', today, 1000, today: today),
        throwsArgumentError,
      );
      await store.endBreak(b, today: today.plus(2));
      expect((await store.breaks()).single.end, today.plus(1));
      expect((await store.entries()).single.day, today.plus(-1));
      expect((await store.plans()).map((p) => p.toMap()).toList(), plans);
      expect(
        (await stats('h', today.plus(2))).state(today),
        DayPlanState.paused,
      );
      await store.setRecord('h', today.plus(2), 1000, today: today.plus(2));
    },
  );
  test(
    'vacation inclusive boundaries and tomorrow expiry restore normal eligibility',
    () async {
      final b = rest(
        'v',
        'h',
        today,
        end: today.plus(2),
        kind: BreakKind.vacation,
      );
      await store.addBreak(b, today: today);
      final app = AppController(store, clock: () => today.date);
      await app.load();
      expect(app.scheduled(app.habits.single, today), isFalse);
      expect(app.scheduled(app.habits.single, today.plus(2)), isFalse);
      expect(app.scheduled(app.habits.single, today.plus(3)), isTrue);
      app.dispose();
    },
  );
  test(
    'skip never deletes a value, duplicates stay one row and removal is explicit',
    () async {
      await store.setRecord('h', today, 0, today: today);
      await expectLater(
        store.addBreak(
          rest('s', 'h', today, end: today, kind: BreakKind.skip),
          today: today,
        ),
        throwsStateError,
      );
      expect((await store.entries()).single.value, 0);
      final b = rest(
        's',
        'h',
        today.plus(-1),
        end: today.plus(-1),
        kind: BreakKind.skip,
      );
      await store.addBreak(b, today: today);
      await store.addBreak(b, today: today);
      expect(
        (await stats('h', today)).state(today.plus(-1)),
        DayPlanState.skipped,
      );
      await store.endBreak(b, today: today);
      await store.endBreak(b, today: today);
      expect(await store.breaks(), isEmpty);
    },
  );
  test(
    'overlaps invalid dates archived future skips and stale finish reject without changes',
    () async {
      final b = rest('p', 'h', today);
      await store.addBreak(b, today: today);
      await expectLater(
        store.addBreak(
          rest(
            'v',
            'h',
            today.plus(1),
            end: today.plus(4),
            kind: BreakKind.vacation,
          ),
          today: today,
        ),
        throwsStateError,
      );
      await expectLater(
        store.endBreak(rest('p', 'h', today, end: today.plus(1)), today: today),
        throwsStateError,
      );
      await store.endBreak(b, today: today);
      await expectLater(
        store.addBreak(rest('x', 'h', today.plus(-1)), today: today),
        throwsArgumentError,
      );
      await expectLater(
        store.addBreak(
          rest(
            'x',
            'h',
            today.plus(1),
            end: today.plus(1),
            kind: BreakKind.skip,
          ),
          today: today,
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.addBreak(
          rest('x', 'h', today, end: today.plus(365), kind: BreakKind.vacation),
          today: today,
        ),
        throwsArgumentError,
      );
      await store.setArchived('h', true, today: today);
      await expectLater(store.addBreak(b, today: today), throwsArgumentError);
    },
  );
  test(
    'daily completion denominator and streak pass rest without counting success',
    () async {
      final start = today.plus(-4);
      await store.setRecord('h', start, 1000, today: today);
      await store.addBreak(
        rest(
          's1',
          'h',
          start.plus(1),
          end: start.plus(1),
          kind: BreakKind.skip,
        ),
        today: today,
      );
      await store.addBreak(
        rest(
          's2',
          'h',
          start.plus(2),
          end: start.plus(2),
          kind: BreakKind.skip,
        ),
        today: today,
      );
      await store.setRecord('h', start.plus(3), 1000, today: today);
      final r = (await stats('h', today)).daily(start, today);
      expect(r.due, 2);
      expect(r.done, 2);
      expect(r.current, 2);
      expect(r.best, 2);
    },
  );
  test(
    'rest week is neutral but archived and partial weeks cannot hide failures',
    () async {
      await store.saveHabit(h('w', weekly: true), create: true);
      final monday = Day.parse('2026-10-19');
      await store.setRecord('w', monday, 1000, today: today);
      await store.setRecord('w', monday.plus(14), 1000, today: today.plus(2));
      await store.addBreak(
        rest(
          's',
          'w',
          monday.plus(7),
          end: monday.plus(7),
          kind: BreakKind.skip,
        ),
        today: today,
      );
      final s = await stats('w', Day.parse('2026-11-09'));
      final r = WeeklySummary(
        s.weeks(monday, Day.parse('2026-11-08')),
        Day.parse('2026-11-08'),
        s,
      );
      expect(r.due, 2);
      expect(r.done, 2);
      expect(r.current, 2);
    },
  );
  test(
    'rest setup never awards cards, remaining obligations can award one, all rest cannot',
    () async {
      await store.saveHabit(h('b'), create: true);
      await store.addBreak(rest('p', 'h', today), today: today);
      expect(await store.cards(), isEmpty);
      await store.setRecord('b', today, 1000, today: today);
      expect((await store.cards()).single.evidence.length, 1);
      await store.addBreak(rest('p2', 'b', today), today: today);
      expect((await store.cards()).length, 1);
      final next = today.plus(1);
      await expectLater(store.claimCard(next, today: next), throwsStateError);
    },
  );
  test(
    'archive history remains ineligible even when covered by a pause',
    () async {
      await store.addBreak(rest('p', 'h', today), today: today);
      await store.setArchived('h', true, today: today.plus(1));
      final s = await stats('h', today.plus(2));
      expect(s.state(today), DayPlanState.paused);
      expect(s.state(today.plus(1)), DayPlanState.archived);
    },
  );
  test(
    'old widget record and old rest page cannot cross pause or restored generation',
    () async {
      final app = AppController(store, clock: () => today.date);
      await app.load();
      await app.run(() => store.addBreak(rest('p', 'h', today), today: today));
      expect(
        await app.recordFromWidget(
          kind: 'habit',
          id: 'h',
          day: today,
          epoch: 0,
        ),
        isFalse,
      );
      final snap = await store.exportSnapshot();
      await app.run(() => store.restoreSnapshot(snap));
      expect(
        await app.run(
          () => store.endBreak((app.rests).single, today: today),
          expectedGeneration: 0,
        ),
        isFalse,
      );
      app.dispose();
    },
  );
  test(
    'schema9 strict rest validation backup rollback and schema8 compatibility',
    () async {
      await store.addBreak(rest('p', 'h', today), today: today);
      final snap = await store.exportSnapshot();
      await store.endBreak((await store.breaks()).single, today: today);
      await store.restoreSnapshot(snap);
      expect((await store.breaks()).length, 1);
      await store.restoreSnapshot(
        (await store.recoverySnapshot())!,
        rollback: true,
      );
      expect(await store.breaks(), isEmpty);
      List<int> mutate(void Function(Map) change) {
        final e = jsonDecode(utf8.decode(snap.encode())) as Map;
        final p = jsonDecode(e['payload']) as Map;
        change(p);
        e['payload'] = jsonEncode(p);
        e['sha256'] = sha256.convert(utf8.encode(e['payload'])).toString();
        return utf8.encode(jsonEncode(e));
      }

      for (final change in <void Function(Map)>[
        (p) => p['tables']['habit_breaks'][0]['kind'] = 'invalid',
        (p) => p['tables']['habit_breaks'][0]['habit_id'] = 'missing',
        (p) => p['tables']['habit_breaks'].add(p['tables']['habit_breaks'][0]),
        (p) => p['tables']['habit_breaks'][0]['end_day'] = '2026-01-01',
      ]) {
        expect(
          () => BackupSnapshot.decode(mutate(change)),
          throwsA(isA<BackupInvalid>()),
        );
      }
      final old = BackupSnapshot.decode(
        mutate((p) {
          p['schema'] = 8;
          (p['tables'] as Map).remove('record_events');
          (p['tables'] as Map).remove('habit_breaks');
        }),
      );
      await store.restoreSnapshot(old);
      expect(await store.breaks(), isEmpty);
    },
  );
  test(
    'v8 migration adds empty rest table only, deleting habit cascades',
    () async {
      await store.db.execute('DROP TABLE habit_breaks');
      await discardV12Fixture(store.db);
      await store.db.setVersion(8);
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/db',
      );
      expect(await store.db.getVersion(), 12);
      expect(await store.breaks(), isEmpty);
      expect((await store.habits()).single.title, 'h');
      await store.addBreak(rest('p', 'h', today), today: today);
      await store.remove('habits', 'h');
      expect(await store.breaks(), isEmpty);
    },
  );
}
