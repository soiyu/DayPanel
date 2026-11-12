import 'package:flutter_test/flutter_test.dart';
import 'package:daypanel/domain/activity.dart';
import 'package:daypanel/domain/habit_break.dart';
import 'package:daypanel/domain/insights.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/record_event.dart';

void main() {
  Day day(String value) => Day.parse(value);

  Habit habit(
    String id, {
    String title = 'Habit',
    Day? start,
    ScheduleKind schedule = ScheduleKind.weekdays,
    int weekdays = 127,
    int weeklyGoal = 3,
    int target = 1000,
  }) => Habit(
    id: id,
    title: title,
    kind: HabitKind.check,
    startDay: start ?? day('2026-10-26'),
    schedule: schedule,
    weekdays: weekdays,
    weeklyGoal: weeklyGoal,
    target: target,
  );

  List<HabitPlan> plans(List<Habit> habits) => [
    for (final item in habits) HabitPlan.fromHabit(item, item.startDay),
  ];
  List<HabitActivity> activity(List<Habit> habits) => [
    for (final item in habits)
      HabitActivity(habitId: item.id, day: item.startDay, archived: false),
  ];
  HabitEntry entry(String habitId, String value, [int amount = 1000]) =>
      HabitEntry(habitId: habitId, day: day(value), value: amount);

  InsightReport build({
    required List<Habit> habits,
    required Day today,
    required Day start,
    required Day end,
    List<HabitPlan>? planList,
    List<HabitActivity>? activityList,
    List<HabitEntry> entries = const [],
    List<HabitBreak> breaks = const [],
    List<Note> notes = const [],
    List<SmallTask> tasks = const [],
    List<TaskEntry> taskEntries = const [],
    List<RecordEvent> events = const [],
  }) => buildInsightReport(
    habits: habits,
    plans: planList ?? plans(habits),
    activity: activityList ?? activity(habits),
    entries: entries,
    breaks: breaks,
    notes: notes,
    tasks: tasks,
    taskEntries: taskEntries,
    events: events,
    today: today,
    start: start,
    end: end,
  );

  test('computes completion, perfect days, streaks and journal totals', () {
    final read = habit('read', title: 'Read');
    final run = habit('run', title: 'Run');
    final entries = <HabitEntry>[
      for (
        var cursor = day('2026-10-26');
        cursor.compareTo(day('2026-11-05')) <= 0;
        cursor = cursor.plus(1)
      )
        entry('read', cursor.key),
      entry('run', '2026-10-27'),
      entry('run', '2026-10-29'),
      entry('run', '2026-11-02'),
    ];
    final report = build(
      habits: [read, run],
      today: day('2026-11-06'),
      start: day('2026-10-26'),
      end: day('2026-11-06'),
      entries: entries,
      notes: [
        Note(id: 'n1', body: 'hello', day: day('2026-10-30')),
        Note(id: 'n2', body: '   ', day: day('2026-10-31')),
        Note(id: 'n3', body: 'outside', day: day('2026-11-06')),
      ],
      tasks: [
        SmallTask(
          id: 't1',
          title: 'Task',
          dueDay: day('2026-11-01'),
          completedDay: day('2026-11-01'),
        ),
      ],
      events: [
        RecordEvent(
          id: 'e1',
          habitId: 'run',
          day: day('2026-11-03'),
          value: 1000,
        ),
        RecordEvent(
          id: 'e2',
          habitId: 'run',
          day: day('2026-11-04'),
          value: 1000,
          note: 'note',
        ),
        RecordEvent(
          id: 'e3',
          habitId: 'run',
          day: day('2026-11-04'),
          value: 1000,
          deleted: true,
        ),
      ],
    );

    expect(report.due, 22);
    expect(report.done, 14);
    expect(report.rate, closeTo(14 / 22, 0.0001));
    expect(report.perfectDays, 3);
    expect(report.activeDays, 11);
    expect(report.journal.notes, 1);
    expect(report.journal.days, 1);
    expect(report.journal.characters, 5);
    expect(report.events, 2);
    expect(report.bestStreak, 11);
    expect(report.bestStreakHabit, 'Read');
    expect(report.habits.first.habitId, 'read');
    expect(report.habits.first.currentStreak, 11);
    expect(report.weekdays[0].due, 4); // two Mondays, two habits
    expect(report.weekdays[4].due, 2); // one Friday, two habits
    expect(report.strongestWeekday, 1);
    expect(report.weakestWeekday, 3);
  });

  test('does not crown a strongest weekday when every day is equal', () {
    final equal = habit('equal');
    final report = build(
      habits: [equal],
      today: day('2026-11-02'),
      start: day('2026-10-26'),
      end: day('2026-11-01'),
    );
    expect(report.due, 7);
    expect(report.done, 0);
    expect(report.strongestWeekday, isNull);
    expect(report.weakestWeekday, isNull);
  });

  test('pauses, skips and archive dates remove days from the denominator', () {
    final paused = habit('paused');
    final pausedReport = build(
      habits: [paused],
      today: day('2026-11-01'),
      start: day('2026-10-26'),
      end: day('2026-10-31'),
      entries: [for (var d = 26; d <= 31; d++) entry('paused', '2026-10-$d')],
      breaks: [
        HabitBreak(
          id: 'b1',
          habitId: 'paused',
          start: day('2026-10-28'),
          end: day('2026-10-29'),
          kind: BreakKind.pause,
        ),
        HabitBreak(
          id: 'b2',
          habitId: 'paused',
          start: day('2026-10-30'),
          end: day('2026-10-30'),
          kind: BreakKind.skip,
        ),
      ],
    );
    expect(pausedReport.due, 3);
    expect(pausedReport.done, 3);

    final archived = habit('archived');
    final archivedReport = build(
      habits: [archived],
      activityList: [
        HabitActivity(
          habitId: 'archived',
          day: day('2026-10-26'),
          archived: false,
        ),
        HabitActivity(
          habitId: 'archived',
          day: day('2026-10-30'),
          archived: true,
        ),
      ],
      today: day('2026-11-01'),
      start: day('2026-10-26'),
      end: day('2026-10-31'),
      entries: [for (var d = 26; d <= 31; d++) entry('archived', '2026-10-$d')],
    );
    expect(archivedReport.due, 4);
    expect(archivedReport.done, 4);
  });

  test('weekly habits count only complete eligible weeks', () {
    final weekly = habit(
      'weekly',
      start: day('2026-10-26'),
      schedule: ScheduleKind.weekly,
      weeklyGoal: 2,
    );
    final report = build(
      habits: [weekly],
      today: day('2026-11-10'),
      start: day('2026-10-26'),
      end: day('2026-11-09'),
      entries: [
        entry('weekly', '2026-10-26'),
        entry('weekly', '2026-10-27'),
        entry('weekly', '2026-11-02'),
        entry('weekly', '2026-11-03'),
        entry('weekly', '2026-11-09'),
      ],
    );
    expect(report.due, 0);
    expect(report.weeklyHabits, hasLength(1));
    final item = report.weeklyHabits.single;
    expect(item.dueWeeks, 2);
    expect(item.doneWeeks, 2);
    expect(item.currentStreak, 2);
    expect(item.bestStreak, 2);
  });

  test('detects same-day co-occurrence above the independent expectation', () {
    final a = habit('a', title: 'Alpha', start: day('2026-10-17'));
    final b = habit('b', title: 'Beta', start: day('2026-10-17'));
    final shared = [for (var d = 0; d < 10; d++) day('2026-10-17').plus(d)];
    final report = build(
      habits: [a, b],
      today: day('2026-11-06'),
      start: day('2026-10-17'),
      end: day('2026-11-05'),
      entries: [
        for (final d in shared) ...[entry('a', d.key), entry('b', d.key)],
      ],
    );
    expect(report.due, 40);
    expect(report.done, 20);
    expect(report.pairs, hasLength(1));
    final pair = report.pairs.single;
    expect(pair.together, 10);
    expect(pair.commonDue, 20);
    expect(pair.lift, closeTo(2, 0.0001));
    expect(pair.liftPercent, 100);
  });

  test('compares against a previous window of the same length', () {
    final habitItem = habit('a', start: day('2026-10-20'));
    final report = build(
      habits: [habitItem],
      today: day('2026-11-06'),
      start: day('2026-11-01'),
      end: day('2026-11-06'),
      entries: [for (var d = 1; d <= 5; d++) entry('a', '2026-11-0$d')],
    );
    expect(report.due, 5);
    expect(report.done, 5);
    expect(report.previousDue, 5);
    expect(report.previousDone, 0);
    expect(report.delta, 1);
    expect(report.habits.single.delta, 1);
    expect(report.habits.single.trend, InsightTrend.up);
  });

  test('empty or fully future windows report nothing', () {
    final report = build(
      habits: [habit('a')],
      today: day('2026-11-06'),
      start: day('2026-11-06'),
      end: day('2026-11-06'),
    );
    expect(report.empty, isTrue);
    expect(report.end, day('2026-11-05'));
    expect(report.due, 0);
    expect(report.weekdays, hasLength(7));
    expect(report.months, isEmpty);
  });

  test('long windows include a month-by-month breakdown', () {
    final yearHabit = habit('year', start: day('2026-01-01'));
    final report = build(
      habits: [yearHabit],
      today: day('2026-11-06'),
      start: day('2026-01-01'),
      end: day('2026-11-06'),
      entries: [
        for (
          var cursor = day('2026-01-01');
          cursor.compareTo(day('2026-11-05')) <= 0;
          cursor = cursor.plus(1)
        )
          entry('year', cursor.key),
      ],
    );
    expect(report.due, 309);
    expect(report.months, hasLength(11));
    expect(report.months.first.month, 1);
    expect(report.months.first.due, 31);
    expect(report.months.last.month, 11);
    expect(report.months.last.due, 5);
    expect(report.months.fold<int>(0, (sum, month) => sum + month.due), 309);
  });
}
