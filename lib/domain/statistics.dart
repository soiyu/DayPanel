import 'activity.dart';
import 'achievement.dart';
import 'models.dart';

enum DayPlanState { future, notStarted, unknown, archived, rest, daily, weekly }

class WeekResult {
  const WeekResult(
    this.start,
    this.achieved,
    this.goal,
    this.eligible,
    this.pending,
  );
  final Day start;
  final int achieved, goal;
  final bool eligible, pending;
  bool get complete => achieved >= goal;
}

class WeeklySummary {
  WeeklySummary(List<WeekResult> weeks, Day end, HabitStatistics stats) {
    Day? previous;
    for (final w in weeks.where((w) => !w.pending)) {
      if (w.eligible) {
        due++;
        if (w.complete) done++;
      }
      if (!w.eligible || !w.complete) {
        current = 0;
      } else {
        if (previous != null && w.start.daysSince(previous) != 7) current = 0;
        current++;
        if (current > best) best = current;
      }
      previous = w.start;
    }
    // A later change out of weekly tracking cannot leave a stale current run.
    if (stats.state(end) != DayPlanState.weekly ||
        (previous != null && end.monday.daysSince(previous) > 7)) {
      current = 0;
    }
  }
  int due = 0, done = 0, current = 0, best = 0;
}

class HabitStatistics {
  HabitStatistics(
    this.habit,
    List<HabitPlan> plans,
    List<HabitActivity> activity,
    List<HabitEntry> entries,
    this.today,
  ) : plans = plans.where((p) => p.habitId == habit.id).toList()
        ..sort((a, b) => a.effectiveDay.compareTo(b.effectiveDay)),
      activity = activity.where((a) => a.habitId == habit.id).toList()
        ..sort((a, b) => a.day.compareTo(b.day)),
      values = {
        for (final e in entries.where((e) => e.habitId == habit.id))
          e.day: e.value,
      };
  final Habit habit;
  final Day today;
  final List<HabitPlan> plans;
  final List<HabitActivity> activity;
  final Map<Day, int> values;
  HabitPlan plan(Day day) => plans.lastWhere(
    (p) => p.effectiveDay.compareTo(day) <= 0,
    orElse: () => HabitPlan.fromHabit(habit, habit.startDay),
  );
  DayPlanState state(Day day) {
    if (day.compareTo(today) > 0) return DayPlanState.future;
    if (day.compareTo(habit.startDay) < 0) return DayPlanState.notStarted;
    final a = activity.where((a) => a.day.compareTo(day) <= 0).lastOrNull;
    if (a == null) return DayPlanState.unknown;
    if (a.archived) return DayPlanState.archived;
    final p = plan(day);
    if (p.schedule == ScheduleKind.weekly) return DayPlanState.weekly;
    return p.scheduled(day) ? DayPlanState.daily : DayPlanState.rest;
  }

  bool achieved(Day day) => (values[day] ?? -1) >= plan(day).target;
  List<Day> days(Day start, Day end) => [
    for (
      var d = start;
      d.compareTo(end) <= 0 && d.compareTo(today) <= 0;
      d = d.plus(1)
    )
      d,
  ];
  DailySummary daily(Day start, Day end) {
    var due = 0, done = 0, current = 0, best = 0;
    for (final d in days(start, end)) {
      final status = state(d);
      if (status == DayPlanState.rest || status == DayPlanState.notStarted) {
        continue;
      }
      if (status != DayPlanState.daily) {
        current = 0;
        continue;
      }
      if (d.compareTo(today) < 0) {
        due++;
        if (achieved(d)) done++;
      }
      if (achieved(d)) {
        current++;
        if (current > best) best = current;
      } else if (d != today) {
        current = 0;
      }
    }
    return DailySummary(due, done, current, best);
  }

  List<WeekResult> weeks(Day start, Day end) {
    final result = <WeekResult>[];
    for (
      var monday = start.monday;
      monday.compareTo(end) <= 0 && monday.compareTo(today) <= 0;
      monday = monday.plus(7)
    ) {
      final daysInWeek = List.generate(7, monday.plus);
      final weekDays = daysInWeek
          .where(
            (d) =>
                d.compareTo(habit.startDay) >= 0 &&
                d.compareTo(start) >= 0 &&
                d.compareTo(end) <= 0 &&
                d.compareTo(today) <= 0 &&
                plan(d).schedule == ScheduleKind.weekly,
          )
          .toList();
      if (weekDays.isEmpty) continue;
      final p = plan(weekDays.last);
      final achievedDays = weekDays
          .where(
            (d) =>
                plan(d).effectiveDay == p.effectiveDay &&
                state(d) == DayPlanState.weekly &&
                achieved(d),
          )
          .length;
      final eligible =
          monday.compareTo(start) >= 0 &&
          monday.plus(6).compareTo(end) <= 0 &&
          daysInWeek.every(
            (d) =>
                state(d) == DayPlanState.weekly &&
                plan(d).effectiveDay == p.effectiveDay,
          );
      result.add(
        WeekResult(
          monday,
          achievedDays,
          p.weeklyGoal,
          eligible,
          monday.plus(6).compareTo(today) >= 0,
        ),
      );
    }
    return result;
  }

  Map<String, List<QuantityPoint>> quantities(Day start, Day end) {
    if (habit.kind != HabitKind.quantity) return {};
    final grouped = <String, List<QuantityPoint>>{};
    for (final d in days(start, end)) {
      final value = values[d];
      if (value == null) continue;
      final p = plan(d);
      grouped
          .putIfAbsent(p.unit, () => [])
          .add(QuantityPoint(d, value, p.target));
    }
    return grouped;
  }
}

class DailySummary {
  const DailySummary(this.due, this.done, this.current, this.best);
  final int due, done, current, best;
}

class QuantityPoint {
  const QuantityPoint(this.day, this.value, this.target);
  final Day day;
  final int value, target;
}

enum TimelineKind { habit, task, note, card }

class TimelineEvent {
  const TimelineEvent({
    required this.day,
    required this.kind,
    required this.id,
    required this.title,
    this.value,
    this.unit,
    this.resident = false,
  });
  final Day day;
  final TimelineKind kind;
  final String id, title;
  final int? value;
  final String? unit;
  final bool resident;
}

List<TimelineEvent> timeline({
  required Day from,
  required Day through,
  required Day today,
  required List<Habit> habits,
  required List<HabitPlan> plans,
  required List<HabitEntry> entries,
  required List<SmallTask> tasks,
  required List<TaskEntry> taskEntries,
  required List<Note> notes,
  required List<AchievementCard> cards,
  TimelineKind? kind,
}) {
  final result = <TimelineEvent>[];
  final habitMap = {for (final h in habits) h.id: h};
  final taskMap = {for (final t in tasks) t.id: t};
  final versionsByHabit = <String, List<HabitPlan>>{};
  for (final p in plans) {
    versionsByHabit.putIfAbsent(p.habitId, () => []).add(p);
  }
  for (final versions in versionsByHabit.values) {
    versions.sort((a, b) => a.effectiveDay.compareTo(b.effectiveDay));
  }
  for (final e in entries) {
    final h = habitMap[e.habitId];
    if (h == null) continue;
    final versions = (versionsByHabit[h.id] ?? <HabitPlan>[]).where(
      (p) => p.effectiveDay.compareTo(e.day) <= 0,
    );
    result.add(
      TimelineEvent(
        day: e.day,
        kind: TimelineKind.habit,
        id: h.id,
        title: h.title,
        value: e.value,
        unit: h.kind == HabitKind.quantity
            ? (versions.lastOrNull?.unit ?? h.unit)
            : null,
      ),
    );
  }
  for (final t in tasks.where((t) => !t.resident && t.completedDay != null)) {
    result.add(
      TimelineEvent(
        day: t.completedDay!,
        kind: TimelineKind.task,
        id: t.id,
        title: t.title,
      ),
    );
  }
  for (final e in taskEntries) {
    final t = taskMap[e.taskId];
    if (t != null) {
      result.add(
        TimelineEvent(
          day: e.day,
          kind: TimelineKind.task,
          id: t.id,
          title: t.title,
          resident: true,
        ),
      );
    }
  }
  for (final n in notes) {
    result.add(
      TimelineEvent(
        day: n.day,
        kind: TimelineKind.note,
        id: n.id,
        title: n.body,
      ),
    );
  }
  for (final c in cards) {
    result.add(
      TimelineEvent(
        day: c.day,
        kind: TimelineKind.card,
        id: c.day.key,
        title: '${c.artwork}',
      ),
    );
  }
  return result
      .where(
        (e) =>
            e.day.compareTo(from) >= 0 &&
            e.day.compareTo(through) <= 0 &&
            e.day.compareTo(today) <= 0 &&
            (kind == null || kind == e.kind),
      )
      .toList()
    ..sort((a, b) {
      final date = b.day.compareTo(a.day);
      if (date != 0) return date;
      final type = a.kind.index.compareTo(b.kind.index);
      return type == 0 ? a.id.compareTo(b.id) : type;
    });
}
