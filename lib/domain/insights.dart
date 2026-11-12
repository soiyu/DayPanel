import 'activity.dart';
import 'habit_break.dart';
import 'models.dart';
import 'record_event.dart';
import 'statistics.dart';

/// Direction of a period-over-period change.
enum InsightTrend { up, down, steady }

/// One daily habit's result inside the selected window.
class HabitInsight {
  const HabitInsight({
    required this.habitId,
    required this.title,
    required this.due,
    required this.done,
    required this.currentStreak,
    required this.bestStreak,
    required this.previousDue,
    required this.previousDone,
  });

  final String habitId, title;
  final int due, done, currentStreak, bestStreak;
  final int previousDue, previousDone;

  double get rate => due == 0 ? 0 : done / due;
  double get previousRate => previousDue == 0 ? 0 : previousDone / previousDue;

  /// Null when the previous window has too little evidence to compare.
  double? get delta => previousDue < 3 ? null : rate - previousRate;

  InsightTrend get trend {
    final change = delta;
    if (change == null || change.abs() < 0.05) return InsightTrend.steady;
    return change > 0 ? InsightTrend.up : InsightTrend.down;
  }
}

/// A weekly-goal habit's result inside the selected window. Only complete,
/// eligible weeks count, matching the weekly statistics screen.
class WeeklyHabitInsight {
  const WeeklyHabitInsight({
    required this.habitId,
    required this.title,
    required this.dueWeeks,
    required this.doneWeeks,
    required this.currentStreak,
    required this.bestStreak,
    required this.total,
    this.unit,
  });

  final String habitId, title;
  final int dueWeeks, doneWeeks, currentStreak, bestStreak;
  final bool total;
  final String? unit;

  double get rate => dueWeeks == 0 ? 0 : doneWeeks / dueWeeks;
}

class WeekdayInsight {
  const WeekdayInsight({
    required this.weekday,
    required this.due,
    required this.done,
  });

  /// ISO weekday, 1 = Monday and 7 = Sunday.
  final int weekday;
  final int due, done;

  double get rate => due == 0 ? 0 : done / due;
}

/// Two daily habits that were completed on the same day more often than
/// their individual completion rates would predict. Co-occurrence is not
/// causation and the UI must say so.
class HabitPairInsight {
  const HabitPairInsight({
    required this.aId,
    required this.aTitle,
    required this.bId,
    required this.bTitle,
    required this.together,
    required this.commonDue,
    required this.expected,
    required this.lift,
  });

  final String aId, aTitle, bId, bTitle;
  final int together, commonDue;
  final double expected, lift;

  /// How far above independent chance the pair is, in percent. A lift of 2.0
  /// means 100% more often than chance, not 200%.
  int get liftPercent => ((lift - 1) * 100).round();
}

class JournalInsight {
  const JournalInsight({
    required this.notes,
    required this.days,
    required this.characters,
  });

  final int notes, days, characters;
}

class MonthInsight {
  const MonthInsight({
    required this.year,
    required this.month,
    required this.due,
    required this.done,
    required this.activeDays,
  });

  final int year, month, due, done, activeDays;

  double get rate => due == 0 ? 0 : done / due;
}

/// A read-only analysis of a closed day window. It is assembled from the same
/// pure [HabitStatistics] rules as the rest of the app, so plans, rests,
/// pauses, archive dates and historical schedule versions are respected.
class InsightReport {
  const InsightReport({
    required this.start,
    required this.end,
    required this.due,
    required this.done,
    required this.perfectDays,
    required this.activeDays,
    required this.previousDue,
    required this.previousDone,
    required this.habits,
    required this.weeklyHabits,
    required this.weekdays,
    required this.pairs,
    required this.journal,
    required this.events,
    required this.months,
    required this.bestStreak,
    required this.bestStreakHabit,
    required this.strongestWeekday,
    required this.weakestWeekday,
  });

  /// First and last day that actually contributed data. Both are closed days
  /// before today; [end] may be before [start] when the window is empty.
  final Day start, end;
  final int due, done, perfectDays, activeDays;
  final int previousDue, previousDone;
  final List<HabitInsight> habits;
  final List<WeeklyHabitInsight> weeklyHabits;
  final List<WeekdayInsight> weekdays;
  final List<HabitPairInsight> pairs;
  final JournalInsight journal;
  final int events;
  final List<MonthInsight> months;
  final int bestStreak;
  final String? bestStreakHabit;

  /// ISO weekdays with the strongest and weakest completion rates. Null when
  /// the window has fewer than three eligible days for that weekday, or when
  /// every eligible weekday performs the same.
  final int? strongestWeekday, weakestWeekday;

  bool get empty => due == 0 && activeDays == 0 && journal.notes == 0;

  double get rate => due == 0 ? 0 : done / due;
  double get previousRate => previousDue == 0 ? 0 : previousDone / previousDue;
  double? get delta => previousDue < 5 ? null : rate - previousRate;

  InsightTrend get trend {
    final change = delta;
    if (change == null || change.abs() < 0.05) return InsightTrend.steady;
    return change > 0 ? InsightTrend.up : InsightTrend.down;
  }
}

/// Builds a report for `[start, end]`, excluding today because the day is not
/// over. The previous window has the same length and is used only for totals
/// and per-habit deltas.
InsightReport buildInsightReport({
  required List<Habit> habits,
  required List<HabitPlan> plans,
  required List<HabitActivity> activity,
  required List<HabitEntry> entries,
  required List<HabitBreak> breaks,
  required List<Note> notes,
  required List<SmallTask> tasks,
  required List<TaskEntry> taskEntries,
  required List<RecordEvent> events,
  required Day today,
  required Day start,
  required Day end,
}) {
  final last = end.compareTo(today) >= 0 ? today.plus(-1) : end;
  if (last.compareTo(start) < 0) {
    return InsightReport(
      start: start,
      end: last,
      due: 0,
      done: 0,
      perfectDays: 0,
      activeDays: 0,
      previousDue: 0,
      previousDone: 0,
      habits: const [],
      weeklyHabits: const [],
      weekdays: [
        for (var weekday = 1; weekday <= 7; weekday++)
          WeekdayInsight(weekday: weekday, due: 0, done: 0),
      ],
      pairs: const [],
      journal: const JournalInsight(notes: 0, days: 0, characters: 0),
      events: 0,
      months: const [],
      bestStreak: 0,
      bestStreakHabit: null,
      strongestWeekday: null,
      weakestWeekday: null,
    );
  }

  final span = last.daysSince(start) + 1;
  final previousEnd = start.plus(-1);
  final previousStart = start.plus(-span);

  final statistics = <String, HabitStatistics>{
    for (final habit in habits)
      habit.id: HabitStatistics(
        habit,
        plans,
        activity,
        entries,
        today,
        breaks: breaks,
      ),
  };

  var due = 0, done = 0, previousDue = 0, previousDone = 0;
  final dayDue = <Day, int>{};
  final dayDone = <Day, int>{};
  final dueDays = <String, Set<Day>>{};
  final achievedDays = <String, Set<Day>>{};
  final habitsInWindow = <HabitInsight>[];
  final weeklyInWindow = <WeeklyHabitInsight>[];

  for (final habit in habits) {
    final stats = statistics[habit.id]!;
    final summary = stats.daily(start, last);
    final previous = stats.daily(previousStart, previousEnd);
    due += summary.due;
    done += summary.done;
    previousDue += previous.due;
    previousDone += previous.done;

    for (var day = start; day.compareTo(last) <= 0; day = day.plus(1)) {
      if (stats.state(day) != DayPlanState.daily) continue;
      dayDue[day] = (dayDue[day] ?? 0) + 1;
      (dueDays[habit.id] ??= <Day>{}).add(day);
      if (stats.achieved(day)) {
        dayDone[day] = (dayDone[day] ?? 0) + 1;
        (achievedDays[habit.id] ??= <Day>{}).add(day);
      }
    }

    if (summary.due > 0) {
      habitsInWindow.add(
        HabitInsight(
          habitId: habit.id,
          title: habit.title,
          due: summary.due,
          done: summary.done,
          currentStreak: summary.current,
          bestStreak: summary.best,
          previousDue: previous.due,
          previousDone: previous.done,
        ),
      );
    }

    final weeks = stats.weeks(start, last);
    final eligible = weeks.where((week) => week.eligible).toList();
    if (eligible.isNotEmpty) {
      final weekly = WeeklySummary(weeks, last, stats);
      weeklyInWindow.add(
        WeeklyHabitInsight(
          habitId: habit.id,
          title: habit.title,
          dueWeeks: eligible.length,
          doneWeeks: eligible.where((week) => week.complete).length,
          currentStreak: weekly.current,
          bestStreak: weekly.best,
          total: habit.schedule == ScheduleKind.weeklyTotal,
          unit: habit.schedule == ScheduleKind.weeklyTotal ? habit.unit : null,
        ),
      );
    }
  }

  habitsInWindow.sort((a, b) {
    final byRate = b.rate.compareTo(a.rate);
    if (byRate != 0) return byRate;
    final byDone = b.done.compareTo(a.done);
    if (byDone != 0) return byDone;
    final byTitle = a.title.compareTo(b.title);
    return byTitle != 0 ? byTitle : a.habitId.compareTo(b.habitId);
  });
  weeklyInWindow.sort((a, b) {
    final byRate = b.rate.compareTo(a.rate);
    if (byRate != 0) return byRate;
    final byDone = b.doneWeeks.compareTo(a.doneWeeks);
    return byDone != 0 ? byDone : a.title.compareTo(b.title);
  });

  final weekdays = <WeekdayInsight>[];
  for (var weekday = 1; weekday <= 7; weekday++) {
    var weekdayDue = 0, weekdayDone = 0;
    for (final entry in dayDue.entries) {
      if (entry.key.date.weekday != weekday) continue;
      weekdayDue += entry.value;
      weekdayDone += dayDone[entry.key] ?? 0;
    }
    weekdays.add(
      WeekdayInsight(weekday: weekday, due: weekdayDue, done: weekdayDone),
    );
  }
  final eligibleWeekdays = weekdays.where((day) => day.due >= 3).toList();
  int? strongest, weakest;
  if (eligibleWeekdays.isNotEmpty) {
    final sorted = [...eligibleWeekdays]
      ..sort((a, b) {
        final byRate = b.rate.compareTo(a.rate);
        return byRate != 0 ? byRate : a.weekday.compareTo(b.weekday);
      });
    final bestRate = sorted.first.rate;
    final worstRate = sorted.last.rate;
    if (sorted.length > 1 && (bestRate - worstRate).abs() >= 0.03) {
      strongest = sorted.first.weekday;
      weakest = sorted.last.weekday;
    }
  }

  final pairs = <HabitPairInsight>[];
  final comparable =
      dueDays.keys.where((id) => (dueDays[id]?.length ?? 0) >= 5).toList()
        ..sort();
  for (var i = 0; i < comparable.length; i++) {
    for (var j = i + 1; j < comparable.length; j++) {
      final a = comparable[i], b = comparable[j];
      final aDue = dueDays[a]!, bDue = dueDays[b]!;
      final commonDue = aDue.intersection(bDue).length;
      if (commonDue < 5) continue;
      final together = (achievedDays[a] ?? const <Day>{})
          .intersection(achievedDays[b] ?? const <Day>{})
          .length;
      if (together < 3) continue;
      final expected =
          commonDue *
          ((achievedDays[a]?.length ?? 0) / aDue.length) *
          ((achievedDays[b]?.length ?? 0) / bDue.length);
      if (expected < 0.5) continue;
      final lift = together / expected;
      if (lift < 1.15) continue;
      pairs.add(
        HabitPairInsight(
          aId: a,
          aTitle: _titleOf(habits, a),
          bId: b,
          bTitle: _titleOf(habits, b),
          together: together,
          commonDue: commonDue,
          expected: expected,
          lift: lift,
        ),
      );
    }
  }
  pairs.sort((a, b) {
    final byTogether = b.together.compareTo(a.together);
    if (byTogether != 0) return byTogether;
    final byLift = b.lift.compareTo(a.lift);
    return byLift != 0 ? byLift : a.aId.compareTo(b.aId);
  });

  final active = <Day>{};
  for (final entry in entries) {
    if (_inWindow(entry.day, start, last)) active.add(entry.day);
  }
  for (final note in notes) {
    if (note.body.trim().isEmpty) continue;
    if (_inWindow(note.day, start, last)) active.add(note.day);
  }
  for (final entry in taskEntries) {
    if (_inWindow(entry.day, start, last)) active.add(entry.day);
  }
  for (final task in tasks) {
    final completed = task.completedDay;
    if (completed != null && _inWindow(completed, start, last)) {
      active.add(completed);
    }
  }
  var eventCount = 0;
  for (final event in events) {
    if (event.deleted || !_inWindow(event.day, start, last)) continue;
    eventCount++;
    active.add(event.day);
  }

  var noteCount = 0, noteCharacters = 0;
  final noteDays = <Day>{};
  for (final note in notes) {
    final body = note.body.trim();
    if (body.isEmpty || !_inWindow(note.day, start, last)) continue;
    noteCount++;
    noteCharacters += body.runes.length;
    noteDays.add(note.day);
  }

  var perfectDays = 0;
  for (final entry in dayDue.entries) {
    if (entry.value > 0 && (dayDone[entry.key] ?? 0) == entry.value) {
      perfectDays++;
    }
  }

  var bestStreak = 0;
  String? bestStreakHabit;
  for (final habit in habitsInWindow) {
    if (habit.bestStreak > bestStreak) {
      bestStreak = habit.bestStreak;
      bestStreakHabit = habit.title;
    }
  }

  final months = <MonthInsight>[];
  if (span >= 120) {
    final byMonth =
        <int, List<int>>{}; // key -> [year, month, due, done, active]
    for (var day = start; day.compareTo(last) <= 0; day = day.plus(1)) {
      final key = day.date.year * 12 + day.date.month;
      final bucket = byMonth.putIfAbsent(
        key,
        () => [day.date.year, day.date.month, 0, 0, 0],
      );
      bucket[2] += dayDue[day] ?? 0;
      bucket[3] += dayDone[day] ?? 0;
      if (active.contains(day)) bucket[4]++;
    }
    final keys = byMonth.keys.toList()..sort();
    for (final key in keys) {
      final bucket = byMonth[key]!;
      months.add(
        MonthInsight(
          year: bucket[0],
          month: bucket[1],
          due: bucket[2],
          done: bucket[3],
          activeDays: bucket[4],
        ),
      );
    }
  }

  return InsightReport(
    start: start,
    end: last,
    due: due,
    done: done,
    perfectDays: perfectDays,
    activeDays: active.length,
    previousDue: previousDue,
    previousDone: previousDone,
    habits: habitsInWindow,
    weeklyHabits: weeklyInWindow,
    weekdays: weekdays,
    pairs: pairs,
    journal: JournalInsight(
      notes: noteCount,
      days: noteDays.length,
      characters: noteCharacters,
    ),
    events: eventCount,
    months: months,
    bestStreak: bestStreak,
    bestStreakHabit: bestStreakHabit,
    strongestWeekday: strongest,
    weakestWeekday: weakest,
  );
}

bool _inWindow(Day day, Day start, Day end) =>
    day.compareTo(start) >= 0 && day.compareTo(end) <= 0;

String _titleOf(List<Habit> habits, String id) =>
    habits.where((habit) => habit.id == id).firstOrNull?.title ?? id;
