import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/activity.dart';
import 'package:daypanel/domain/achievement.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/statistics.dart';

void main() {
  sqfliteFfiInit();
  final today = Day.parse('2026-11-06');
  final start = Day.parse('2026-10-19');
  Habit habit({
    HabitKind kind = HabitKind.check,
    ScheduleKind schedule = ScheduleKind.weekdays,
    int weekdays = 127,
    int interval = 1,
  }) => Habit(
    id: 'h',
    title: 'Read',
    kind: kind,
    startDay: start,
    schedule: schedule,
    weekdays: weekdays,
    intervalDays: interval,
    weeklyGoal: 2,
  );
  HabitStatistics stats(
    Habit h,
    List<HabitEntry> entries, {
    List<HabitPlan>? plans,
    List<HabitActivity>? activity,
    Day? now,
  }) => HabitStatistics(
    h,
    plans ?? [HabitPlan.fromHabit(h, start)],
    activity ?? [HabitActivity(habitId: 'h', day: start, archived: false)],
    entries,
    now ?? today,
  );
  HabitEntry entry(String day, int value) =>
      HabitEntry(habitId: 'h', day: Day.parse(day), value: value);
  test(
    'daily denominator ends yesterday and counts known planned days only',
    () {
      final h = habit(weekdays: 31);
      final s = stats(h, [
        entry('2026-11-02', 1000),
        entry('2026-11-03', 0),
        entry('2026-11-05', 1000),
        entry('2026-11-01', 1000),
      ]);
      final result = s.daily(Day.parse('2026-11-01'), today);
      expect(result.due, 4);
      expect(result.done, 2);
      expect(result.current, 1);
      expect(result.best, 1);
      expect(s.state(today.plus(1)), DayPlanState.future);
      expect(s.state(start.plus(-1)), DayPlanState.notStarted);
    },
  );
  test('rest days skip streak and uncompleted today does not break it', () {
    final h = habit(weekdays: 31);
    final entries = [
      for (
        var d = Day.parse('2026-10-30');
        d.compareTo(today) < 0;
        d = d.plus(1)
      )
        if (d.date.weekday <= 5) HabitEntry(habitId: 'h', day: d, value: 1000),
    ];
    var result = stats(h, entries).daily(Day.parse('2026-10-30'), today);
    expect(result.current, 5);
    expect(result.best, 5);
    expect(result.due, 5);
    expect(result.done, 5);
    entries.add(entry(today.key, 1000));
    result = stats(h, entries).daily(Day.parse('2026-10-30'), today);
    expect(result.current, 6);
    expect(result.due, 5);
    expect(stats(h, entries).daily(today, today).due, 0);
  });
  test(
    'unknown archive and reactivation delimit rate and streak without erasing values',
    () {
      final h = habit();
      final activity = [
        HabitActivity(
          habitId: 'h',
          day: Day.parse('2026-11-02'),
          archived: false,
        ),
        HabitActivity(
          habitId: 'h',
          day: Day.parse('2026-11-03'),
          archived: true,
        ),
        HabitActivity(
          habitId: 'h',
          day: Day.parse('2026-11-05'),
          archived: false,
        ),
      ];
      final s = stats(h, [
        entry('2026-11-01', 1000),
        entry('2026-11-02', 1000),
        entry('2026-11-03', 1000),
        entry('2026-11-05', 1000),
      ], activity: activity);
      expect(s.state(Day.parse('2026-11-01')), DayPlanState.unknown);
      expect(s.state(Day.parse('2026-11-04')), DayPlanState.archived);
      final result = s.daily(Day.parse('2026-11-01'), today);
      expect(result.due, 2);
      expect(result.done, 2);
      expect(result.current, 1);
      expect(result.best, 1);
      expect(s.values.length, 4);
    },
  );
  test('interval plan anchor and historic targets remain versioned', () {
    final h = habit(
      kind: HabitKind.quantity,
      schedule: ScheduleKind.interval,
      interval: 2,
    );
    final plans = [
      HabitPlan.fromHabit(h, start),
      HabitPlan(
        habitId: 'h',
        effectiveDay: Day.parse('2026-11-03'),
        target: 2000,
        unit: 'cups',
        schedule: ScheduleKind.interval,
        intervalDays: 3,
      ),
    ];
    final s = stats(h, [
      entry('2026-11-02', 1000),
      entry('2026-11-03', 1000),
      entry('2026-11-06', 2000),
    ], plans: plans);
    expect(s.state(Day.parse('2026-11-02')), DayPlanState.daily);
    expect(s.state(Day.parse('2026-11-04')), DayPlanState.rest);
    expect(s.achieved(Day.parse('2026-11-02')), isTrue);
    expect(s.achieved(Day.parse('2026-11-03')), isFalse);
    final r = s.daily(Day.parse('2026-11-02'), today);
    expect(r.due, 2);
    expect(r.done, 1);
    expect(r.current, 1);
  });
  test(
    'weekly complete periods exclude partial version changes and ongoing week',
    () {
      final h = habit(schedule: ScheduleKind.weekly);
      final s = stats(h, [
        entry('2026-10-19', 1000),
        entry('2026-10-21', 1000),
        entry('2026-10-26', 1000),
        entry('2026-10-27', 1000),
        entry('2026-11-02', 1000),
      ]);
      final weeks = s.weeks(start, today);
      final r = WeeklySummary(weeks, today, s);
      expect(r.due, 2);
      expect(r.done, 2);
      expect(r.current, 2);
      expect(r.best, 2);
      expect(weeks.last.pending, isTrue);
      expect(s.daily(start, today).due, 0);
      final changed = stats(
        h,
        [],
        plans: [
          HabitPlan.fromHabit(h, start),
          HabitPlan(
            habitId: 'h',
            effectiveDay: Day.parse('2026-10-28'),
            target: 1000,
            unit: '',
            schedule: ScheduleKind.weekly,
            weeklyGoal: 3,
          ),
        ],
      );
      expect(changed.weeks(start, today)[1].eligible, isFalse);
      expect(changed.weeks(start.plus(2), today).first.eligible, isFalse);
    },
  );
  test(
    'weekly historical values do not cross versions and range edges are not counted',
    () {
      final h = habit(kind: HabitKind.quantity, schedule: ScheduleKind.weekly);
      final s = stats(
        h,
        [
          entry('2026-10-26', 1000),
          entry('2026-10-27', 1000),
          entry('2026-10-28', 1000),
          entry('2026-10-29', 2000),
        ],
        plans: [
          HabitPlan.fromHabit(h, start),
          HabitPlan(
            habitId: 'h',
            effectiveDay: Day.parse('2026-10-28'),
            target: 2000,
            unit: 'ml',
            schedule: ScheduleKind.weekly,
            weeklyGoal: 2,
          ),
        ],
      );
      final week = s
          .weeks(Day.parse('2026-10-26'), Day.parse('2026-10-29'))
          .single;
      expect(week.eligible, isFalse);
      expect(week.achieved, 1);
      expect(week.goal, 2);
    },
  );
  test(
    'quantity grouping includes exact zero but excludes missing dates and splits units',
    () {
      final h = habit(kind: HabitKind.quantity);
      final s = stats(
        h,
        [
          entry('2026-11-01', 0),
          entry('2026-11-02', 250001),
          entry('2026-11-04', 2000),
        ],
        plans: [
          HabitPlan(
            habitId: 'h',
            effectiveDay: start,
            target: 2000000,
            unit: 'ml',
          ),
          HabitPlan(
            habitId: 'h',
            effectiveDay: Day.parse('2026-11-03'),
            target: 2000,
            unit: 'cups',
          ),
        ],
      );
      final groups = s.quantities(Day.parse('2026-11-01'), today);
      expect(groups.keys, ['ml', 'cups']);
      expect(groups['ml']!.length, 2);
      expect(groups['ml']!.first.value, 0);
      expect(groups['ml']!.last.value, 250001);
      expect(groups['cups']!.single.target, 2000);
    },
  );
  test('leap calendar days and year boundaries use calendar arithmetic', () {
    final h = Habit(
      id: 'h',
      title: 'Leap',
      kind: HabitKind.check,
      startDay: Day.parse('2024-01-01'),
    );
    final s = stats(h, [], now: Day.parse('2024-12-31'));
    expect(
      s.days(Day.parse('2024-01-01'), Day.parse('2024-12-31')).length,
      366,
    );
    expect(Day.parse('2024-02-28').plus(1).key, '2024-02-29');
    expect(Day.parse('2026-12-31').plus(1).key, '2027-01-01');
  });
  test(
    'timeline uses task actual dates, all record types, zero values and stable order',
    () {
      final h = habit(kind: HabitKind.quantity);
      final tasks = [
        SmallTask(
          id: 'once',
          title: 'Once',
          dueDay: today.plus(2),
          completedDay: today.plus(-1),
        ),
        SmallTask(
          id: 'r',
          title: 'Resident',
          resident: true,
          startDay: start,
          archived: true,
        ),
      ];
      final card = AchievementCard(
        day: today,
        artwork: AchievementCard.artworkFor(today),
        evidence: [
          CardHabit(
            id: 'h',
            title: 'Read',
            kind: HabitKind.check,
            target: 1000,
            unit: '',
            value: 1000,
            planDay: start,
          ),
        ],
      );
      final result = timeline(
        from: today.plus(-1),
        through: today,
        today: today,
        habits: [h],
        plans: [
          HabitPlan(
            habitId: 'h',
            effectiveDay: start,
            target: 1000,
            unit: 'ml',
          ),
        ],
        entries: [entry(today.key, 0)],
        tasks: tasks,
        taskEntries: [TaskEntry(taskId: 'r', day: today)],
        notes: [Note(id: 'n', body: 'Remember', day: today)],
        cards: [card],
      );
      expect(result.map((e) => e.kind), [
        TimelineKind.habit,
        TimelineKind.task,
        TimelineKind.note,
        TimelineKind.card,
        TimelineKind.task,
      ]);
      expect(result.first.value, 0);
      expect(result.first.unit, 'ml');
      expect(result.last.day, today.plus(-1));
      expect(result[1].resident, isTrue);
      final cleared = timeline(
        from: today,
        through: today,
        today: today,
        habits: [h],
        plans: [],
        entries: [],
        tasks: [],
        taskEntries: [],
        notes: [],
        cards: [card],
      );
      expect(cleared.single.kind, TimelineKind.card);
    },
  );
  group('persistent activity and compatibility', () {
    late AppStore store;
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('daypanel-stats-');
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/db',
      );
      await store.saveHabit(habit(), create: true);
    });
    tearDown(() async {
      await store.close();
      await dir.delete(recursive: true);
    });
    test(
      'archive days persist same-day explicit changes and do not rewrite previous days',
      () async {
        await store.setArchived('h', true, today: today.plus(-2));
        await store.setArchived('h', true, today: today.plus(-1));
        await store.setArchived('h', false, today: today);
        expect((await store.activity()).length, 3);
        await store.setArchived('h', true, today: today);
        expect((await store.activity()).length, 3);
        await store.setArchived('h', false, today: today);
        await store.close();
        store = await AppStore.open(
          factory: databaseFactoryFfi,
          path: '${dir.path}/db',
        );
        final s = stats(
          (await store.habits()).single,
          [],
          activity: await store.activity(),
        );
        expect(s.state(today.plus(-3)), DayPlanState.daily);
        expect(s.state(today.plus(-1)), DayPlanState.archived);
        expect(s.state(today), DayPlanState.daily);
        await expectLater(
          store.setArchived('h', true, today: today.plus(-1)),
          throwsStateError,
        );
      },
    );
    test(
      'v6 migration establishes known baseline today and preserves all original facts',
      () async {
        await store.setRecord('h', today.plus(-5), 1000, today: today);
        await store.db.execute('DROP TABLE habit_activity');
        await store.db.execute('ALTER TABLE habits DROP COLUMN color');
        await store.db.execute('ALTER TABLE habits DROP COLUMN frame');
        await store.db.execute('DROP TABLE habit_breaks');
        await store.db.setVersion(6);
        await store.close();
        store = await AppStore.open(
          factory: databaseFactoryFfi,
          path: '${dir.path}/db',
          migrationDay: today,
        );
        expect(await store.db.getVersion(), 11);
        expect((await store.activity()).single.day, today);
        final s = stats(
          (await store.habits()).single,
          await store.entries(),
          activity: await store.activity(),
        );
        expect(s.state(today.plus(-1)), DayPlanState.unknown);
        expect(s.daily(start, today).due, 0);
        expect(s.values.length, 1);
      },
    );
    test(
      'backup restores activity history and rejects missing duplicated or mismatched histories',
      () async {
        await store.setArchived('h', true, today: today.plus(-1));
        final snap = await store.exportSnapshot();
        await store.setArchived('h', false, today: today);
        await store.restoreSnapshot(snap);
        expect((await store.activity()).last.archived, isTrue);
        await store.restoreSnapshot(
          (await store.recoverySnapshot())!,
          rollback: true,
        );
        expect((await store.activity()).last.archived, isFalse);
        for (final mutate in <void Function(Map)>[
          (p) => p['tables']['habit_activity'] = [],
          (p) => p['tables']['habit_activity'][0]['habit_id'] = 'missing',
          (p) => p['tables']['habit_activity'][1]['archived'] = 0,
          (p) => (p['tables']['habit_activity'] as List).add(
            p['tables']['habit_activity'][0],
          ),
        ]) {
          final e = jsonDecode(utf8.decode(snap.encode())) as Map;
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
    for (final schema in [2, 3, 4, 5, 6]) {
      test(
        'schema$schema establishes baseline at backup date and restores previous activity on rollback',
        () async {
          final snap = await store.exportSnapshot(now: today.date.toUtc());
          final e = jsonDecode(utf8.decode(snap.encode())) as Map;
          final p = jsonDecode(e['payload'] as String) as Map;
          p['schema'] = schema;
          (p['tables'] as Map).remove('habit_breaks');
          for (final h in p['tables']['habits'] as List) {
            (h as Map).remove('color');
            h.remove('frame');
          }
          (p['tables'] as Map).remove('habit_activity');
          if (schema < 6) (p['tables'] as Map).remove('cards');
          if (schema < 4) (p['tables'] as Map).remove('task_entries');
          if (schema < 3) (p['tables'] as Map).remove('reminders');
          e['payload'] = jsonEncode(p);
          e['sha256'] = sha256
              .convert(utf8.encode(e['payload'] as String))
              .toString();
          final old = BackupSnapshot.decode(utf8.encode(jsonEncode(e)));
          await store.restoreSnapshot(old);
          expect((await store.activity()).single.day, today);
          await store.restoreSnapshot(
            (await store.recoverySnapshot())!,
            rollback: true,
          );
          expect((await store.activity()).single.day, start);
        },
      );
    }
    test(
      'restore makes old correction stale and cannot alter the restored date',
      () async {
        final app = AppController(store, clock: () => today.date);
        await app.load();
        final epoch = app.generation;
        final snap = await store.exportSnapshot();
        await app.run(() => store.restoreSnapshot(snap));
        expect(
          await app.recordHabit(habit(), today.plus(-1), 1000, epoch),
          isFalse,
        );
        expect(await store.entries(), isEmpty);
        app.dispose();
      },
    );
  });
}
