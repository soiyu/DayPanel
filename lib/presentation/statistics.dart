import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../domain/statistics.dart';
import '../l10n/app_localizations.dart';
import 'achievements.dart';
import 'components.dart';
import 'editors.dart';
import 'tasks.dart';
import 'theme.dart';
import 'refined_components.dart';
import 'rest_days.dart';

HabitStatistics statsFor(AppController app, Habit h) => HabitStatistics(
  h,
  app.plans,
  app.activity,
  app.entries,
  app.today,
  breaks: app.rests,
);
String dateLabel(BuildContext context, Day day) => DateFormat.yMMMd(
  Localizations.localeOf(context).languageCode,
).format(day.date);
String stateLabel(AppLocalizations s, DayPlanState state) => switch (state) {
  DayPlanState.future => s.futureDate,
  DayPlanState.notStarted => s.notStarted,
  DayPlanState.unknown => s.historyUnknown,
  DayPlanState.archived => s.archived,
  DayPlanState.rest => s.notScheduled,
  DayPlanState.paused => s.restPaused,
  DayPlanState.skipped => s.restSkipped,
  DayPlanState.daily => s.planned,
  DayPlanState.weekly => s.weeklyAvailable,
};

Future<void> correctRecord(
  BuildContext context,
  AppController app,
  Habit h,
  Day day,
) async {
  final s = AppLocalizations.of(context);
  final epoch = app.generation;
  final stats = statsFor(app, h);
  final current = stats.values[day];
  final rest = app.restOn(h, day);
  final canWrite =
      !h.archived &&
      app.restOn(h, day) == null &&
      day.compareTo(h.startDay) >= 0 &&
      day.compareTo(app.today) <= 0;
  if (canWrite && h.kind.isNumeric) {
    await openQuantity(context, app, h, day);
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        return ListenableBuilder(
          listenable: app,
          builder: (ctx, _) => SheetFrame(
            title: h.title,
            subtitle:
                '${dateLabel(ctx, day)}\n${stateLabel(s, stats.state(day))}',
            icon: Icons.fact_check_outlined,
            tone: UiTone.violet,
            busy: app.busy,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  current != null && h.kind.isNumeric
                      ? '${quantityText(current)} / ${quantityText(stats.plan(day).target)} ${stats.plan(day).unit}'
                      : current == null
                      ? s.notRecorded
                      : current >= stats.plan(day).target
                      ? s.finished
                      : s.notCompleted,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  rest != null
                      ? restRecordHint(s, rest, day, app.today)
                      : s.correctionHint,
                ),
                if (h.archived) Text(s.restoreToCorrect),
                if (app.error != null)
                  Text(
                    s.storageError,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                if (canWrite) ...[
                  const SizedBox(height: 16),
                  AppAction(
                    key: const Key('confirm-habit-record'),
                    label: s.recordThisDay,
                    icon: Icons.check_rounded,
                    primary: true,
                    onTap: app.busy
                        ? null
                        : () async {
                            final ok = await app.recordHabit(
                              h,
                              day,
                              1000,
                              epoch,
                            );
                            if (ok && ctx.mounted) Navigator.pop(ctx);
                          },
                  ),
                  if (current != null) ...[
                    const SizedBox(height: 10),
                    AppAction(
                      key: const Key('clear-habit-record'),
                      label: s.clearRecord,
                      icon: Icons.undo_rounded,
                      tone: UiTone.peach,
                      onTap: app.busy
                          ? null
                          : () async {
                              final ok = await app.recordHabit(
                                h,
                                day,
                                null,
                                epoch,
                              );
                              if (ok && ctx.mounted) Navigator.pop(ctx);
                            },
                    ),
                  ],
                ],
              ],
            ),
            footer: AppAction(
              label: s.cancel,
              onTap: app.busy ? null : () => Navigator.pop(ctx),
            ),
          ),
        );
      },
    ),
  );
}

Future<String?> selectStatisticsHabit(
  BuildContext context,
  AppController app,
  String? selected,
) {
  final s = AppLocalizations.of(context);
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => SheetFrame(
      title: s.filterHabits,
      icon: Icons.tune_rounded,
      tone: UiTone.violet,
      body: Column(
        children: [
          SettingRow(
            icon: Icons.grid_view_rounded,
            title: s.allHabits,
            onTap: () => Navigator.pop(ctx, ''),
          ),
          for (final h in app.habits)
            SettingRow(
              icon: h.id == selected
                  ? Icons.check_circle_outline
                  : Icons.spa_outlined,
              title: h.title,
              subtitle: h.archived ? s.archived : null,
              onTap: () => Navigator.pop(ctx, h.id),
            ),
        ],
      ),
      footer: AppAction(label: s.cancel, onTap: () => Navigator.pop(ctx)),
    ),
  );
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    super.key,
    required this.app,
    this.habitId,
    this.initialTab = 0,
    this.initialDay,
  });
  final AppController app;
  final String? habitId;
  final int initialTab;
  final Day? initialDay;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late int tab, year, calendarMonth;
  late Day week, month, through;
  Day? timelineDay;
  String? habitId;
  TimelineKind? timelineKind;
  int range = 30;
  AppController get app => widget.app;
  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
    habitId = widget.habitId;
    final requested = widget.initialDay ?? app.today;
    through = requested.compareTo(app.today) > 0 ? app.today : requested;
    week = through.monday;
    month = Day(DateTime(through.date.year, through.date.month));
    year = through.date.year;
    calendarMonth = through.date.month;
    timelineDay = widget.initialDay == null ? null : through;
  }

  Future<void> locate() async {
    final initial = tab == 1
        ? through
        : tab == 3
        ? timelineDay ?? month
        : tab == 2
        ? Day(DateTime(year))
        : week;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.compareTo(app.today) > 0
          ? app.today.date
          : initial.date,
      firstDate: DateTime(1900),
      lastDate: app.today.date,
    );
    if (picked != null && mounted) {
      setState(() {
        through = Day(picked);
        week = through.monday;
        month = Day(DateTime(picked.year, picked.month));
        year = picked.year;
        calendarMonth = picked.month;
        timelineDay = Day(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final selected = app.habits.where((h) => h.id == habitId).firstOrNull;
      final habits = selected == null ? app.habits : [selected];
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.statisticsTitle),
            actions: [
              if (through != app.today ||
                  week != app.today.monday ||
                  month !=
                      Day(
                        DateTime(app.today.date.year, app.today.date.month),
                      ) ||
                  year != app.today.date.year ||
                  calendarMonth != app.today.date.month ||
                  timelineDay != null)
                IconButton(
                  key: const Key('statistics-latest'),
                  tooltip: s.pmRecentStatistics,
                  icon: const Icon(Icons.today_outlined),
                  onPressed: () => setState(() {
                    through = app.today;
                    week = app.today.monday;
                    month = Day(
                      DateTime(app.today.date.year, app.today.date.month),
                    );
                    year = app.today.date.year;
                    calendarMonth = app.today.date.month;
                    timelineDay = null;
                  }),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: Semantics(
                          selected: tab == i,
                          button: true,
                          label: [
                            s.checkinTable,
                            s.habitStatistics,
                            s.yearCalendar,
                            s.timelineTitle,
                          ][i],
                          child: Material(
                            color: tab == i
                                ? UiTone.violet.wash(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: Key('statistics-tab-$i'),
                              onTap: () => setState(() => tab = i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      [
                                        Icons.table_chart_outlined,
                                        Icons.bar_chart_rounded,
                                        Icons.calendar_month_outlined,
                                        Icons.timeline_rounded,
                                      ][i],
                                      size: 21,
                                      color: tab == i
                                          ? UiTone.violet.ink(context)
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      [
                                        s.uiTabTable,
                                        s.uiTabHabits,
                                        s.uiTabYear,
                                        s.uiTabTimeline,
                                      ][i],
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: tab == i
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: tab == i
                                                ? UiTone.violet.ink(context)
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (tab != 3) ...[
                AppAction(
                  key: const Key('statistics-habit-filter'),
                  label: selected == null
                      ? s.allHabits
                      : '${selected.title}${selected.archived ? ' (${s.archived})' : ''}',
                  icon: Icons.tune_rounded,
                  tone: UiTone.violet,
                  onTap: () async {
                    final choice = await selectStatisticsHabit(
                      context,
                      app,
                      habitId,
                    );
                    if (choice != null && mounted) {
                      setState(() => habitId = choice.isEmpty ? null : choice);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (tab == 0) ...matrix(context, habits),
              if (tab == 1) ...summary(context, selected),
              if (tab == 2) ...calendar(context, habits),
              if (tab == 3) ...events(context),
            ],
          ),
        ),
      );
    },
  );
  Widget period(
    BuildContext context,
    String title,
    VoidCallback? previous,
    VoidCallback? next,
  ) {
    final s = AppLocalizations.of(context);
    return SoftPanel(
      tinted: true,
      tone: UiTone.peach,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          IconButton(
            key: const Key('period-previous'),
            tooltip: s.previousPeriod,
            onPressed: previous,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            key: const Key('period-next'),
            tooltip: s.nextPeriod,
            onPressed: next,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          IconButton(
            key: const Key('statistics-locate'),
            tooltip: s.locateDate,
            onPressed: locate,
            icon: const Icon(Icons.event_outlined),
          ),
        ],
      ),
    );
  }

  List<Widget> matrix(BuildContext context, List<Habit> habits) {
    final s = AppLocalizations.of(context);
    final dates = List.generate(7, week.plus);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final width = 54.0 * scale;
    return [
      period(
        context,
        '${week.key} — ${week.plus(6).key}',
        week.date.year <= 1900 && week.date.month == 1
            ? null
            : () => setState(() => week = week.plus(-7)),
        week.plus(7).compareTo(app.today) > 0
            ? null
            : () => setState(() => week = week.plus(7)),
      ),
      const SizedBox(height: 12),
      const SizedBox(height: 16),
      if (habits.isEmpty)
        EmptyState(
          icon: Icons.table_chart_outlined,
          title: s.emptyHabits,
          body: s.emptyHabitsBody,
          tone: UiTone.violet,
        ),
      if (habits.isNotEmpty)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 60 * scale,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        s.habit,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  for (final h in habits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, right: 8),
                      child: SizedBox(
                        height: 56 * scale,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Tooltip(
                            message:
                                '${h.title}${h.archived ? ' (${s.archived})' : ''}',
                            child: Text(
                              '${h.title}${h.archived ? ' (${s.archived})' : ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (final d in dates)
                          SizedBox(
                            width: width,
                            height: 60 * scale,
                            child: Center(
                              child: Text(
                                '${d.date.month}/${d.date.day}\n${DateFormat.E(Localizations.localeOf(context).languageCode).format(d.date)}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                      ],
                    ),
                    for (final h in habits)
                      _matrixRow(context, h, dates, width, scale),
                  ],
                ),
              ),
            ),
          ],
        ),
      DetailDisclosure(
        title: s.uiStatisticsHelp,
        child: Text(s.tableHint, style: Theme.of(context).textTheme.bodySmall),
      ),
      const SizedBox(height: 18),
      if (habits.any(
        (h) =>
            dates.any((d) => statsFor(app, h).state(d) == DayPlanState.unknown),
      ))
        Text(
          s.statisticsKnownHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ];
  }

  Widget _matrixRow(
    BuildContext context,
    Habit h,
    List<Day> dates,
    double width,
    double scale,
  ) {
    final s = AppLocalizations.of(context);
    final stats = statsFor(app, h);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (final day in dates)
            Builder(
              builder: (context) {
                final state = stats.state(day);
                final value = stats.values[day];
                final title = value != null
                    ? (stats.achieved(day) ? s.finished : s.notCompleted)
                    : state == DayPlanState.daily
                    ? s.notRecorded
                    : stateLabel(s, state);
                final symbol = value != null
                    ? (stats.achieved(day) ? '✓' : '•')
                    : switch (state) {
                        DayPlanState.daily => '○',
                        DayPlanState.weekly => '~',
                        DayPlanState.unknown => '?',
                        DayPlanState.paused => 'Ⅱ',
                        DayPlanState.skipped => '↷',
                        _ => '—',
                      };
                final canOpen =
                    state != DayPlanState.future &&
                    state != DayPlanState.notStarted;
                return SizedBox(
                  width: width,
                  height: 56 * scale,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Semantics(
                      label:
                          '${h.title}, ${day.key}, $title${value == null ? '' : ', ${quantityText(value)} ${stats.plan(day).unit}'}',
                      button: canOpen,
                      onTap: canOpen
                          ? () => correctRecord(context, app, h, day)
                          : null,
                      child: ExcludeSemantics(
                        child: Material(
                          color: value == null
                              ? Theme.of(context).colorScheme.surface
                              : UiTone.violet.wash(context),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            key: Key('matrix-${h.id}-${day.key}'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: canOpen
                                ? () => correctRecord(context, app, h, day)
                                : null,
                            child: Center(
                              child: Text(
                                symbol,
                                style: TextStyle(
                                  fontSize: 21,
                                  color: value != null
                                      ? UiTone.violet.ink(context)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Widget> summary(BuildContext context, Habit? selected) {
    final s = AppLocalizations.of(context);
    if (selected == null) {
      return [
        EmptyState(
          icon: Icons.bar_chart_rounded,
          title: s.chooseStatisticsHabit,
          body: s.singleHabitStatistics,
          tone: UiTone.violet,
        ),
      ];
    }
    final stats = statsFor(app, selected);
    final start = through.plus(1 - range);
    final result = stats.daily(start, through);
    final weeks = stats.weeks(start, through);
    final weekly = WeeklySummary(weeks, through, stats);
    final quantities = stats.quantities(start, through);
    final hasDailyPlan = stats
        .days(start, through)
        .any(
          (d) =>
              d.compareTo(selected.startDay) >= 0 &&
              stats.plan(d).schedule != ScheduleKind.weekly,
        );
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final n in [7, 30, 365])
            AppAction(
              key: Key('statistics-range-$n'),
              label: '$n ${s.daysLabel}',
              primary: range == n,
              onTap: () => setState(() => range = n),
            ),
        ],
      ),
      const SizedBox(height: 14),
      period(
        context,
        '${start.key} — ${through.key}',
        through.plus(-range).date.year < 1900
            ? null
            : () => setState(() => through = through.plus(-range)),
        through == app.today
            ? null
            : () => setState(() {
                final next = through.plus(range);
                through = next.compareTo(app.today) > 0 ? app.today : next;
              }),
      ),
      const SizedBox(height: 12),
      if (selected.kind.isNumeric) ...[
        const SizedBox(height: 20),
        SectionTitle(
          s.quantityStatistics,
          key: const Key('quantity-statistics'),
          tone: UiTone.blue,
        ),
        Text(s.quantityStatsHint, style: Theme.of(context).textTheme.bodySmall),
        if (quantities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(s.noRecordedValues),
          ),
        for (final group in quantities.entries) ...[
          const SizedBox(height: 16),
          QuantityTrend(
            points: group.value,
            unit: group.key,
            app: app,
            habit: selected,
          ),
        ],
      ],
      if (hasDailyPlan)
        SoftPanel(
          key: const Key('daily-statistics'),
          tinted: true,
          tone: UiTone.violet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.dailyCompletionRate,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                result.due == 0
                    ? s.noDenominator
                    : '${(100 * result.done / result.due).toStringAsFixed(1)}%  (${result.done}/${result.due})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                s.dailyRateHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  AppBadge(
                    '${s.currentRun} ${result.current}',
                    tone: UiTone.violet,
                  ),
                  AppBadge('${s.bestRun} ${result.best}', tone: UiTone.peach),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.streakRangeHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      if (weeks.isNotEmpty) ...[
        const SizedBox(height: 18),
        SectionTitle(
          s.weeklyStatistics,
          key: const Key('weekly-statistics'),
          tone: UiTone.violet,
        ),
        SoftPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                weekly.due == 0
                    ? s.noFullWeeks
                    : '${(100 * weekly.done / weekly.due).toStringAsFixed(1)}% (${weekly.done}/${weekly.due} ${s.completedWeeks})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                s.weeklyStatsHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Text(
                '${s.currentWeeks} ${weekly.current} · ${s.bestWeeks} ${weekly.best}',
              ),
              for (final w in weeks.reversed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${w.start.key}  ${w.achieved}/${w.goal} · ${w.pending
                        ? s.inProgress
                        : !w.eligible
                        ? s.partialPeriod
                        : w.complete
                        ? s.finished
                        : s.notCompleted}',
                  ),
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      if (stats
          .days(start, through)
          .any((d) => stats.state(d) == DayPlanState.unknown))
        Text(
          s.statisticsKnownHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      const SizedBox(height: 16),
      SectionTitle(s.history, tone: UiTone.violet),
      for (final d
          in stats
              .days(start, through)
              .reversed
              .where((d) => stats.values[d] != null))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SoftPanel(
            padding: EdgeInsets.zero,
            child: SettingRow(
              icon: stats.achieved(d)
                  ? Icons.check_circle_outline
                  : Icons.circle_outlined,
              title: dateLabel(context, d),
              subtitle:
                  '${quantityText(stats.values[d]!)} / ${quantityText(stats.plan(d).target)} ${stats.plan(d).unit}\n${stateLabel(s, stats.state(d))}',
              onTap: () => correctRecord(context, app, selected, d),
            ),
          ),
        ),
    ];
  }

  List<Widget> calendar(BuildContext context, List<Habit> habits) {
    final s = AppLocalizations.of(context);
    final ids = habits.map((h) => h.id).toSet();
    final counts = <Day, int>{};
    for (final e in app.entries.where(
      (e) =>
          ids.contains(e.habitId) &&
          e.day.date.year == year &&
          e.day.compareTo(app.today) <= 0,
    )) {
      counts.update(e.day, (v) => v + 1, ifAbsent: () => 1);
    }
    return [
      period(
        context,
        '$year',
        year <= 1900 ? null : () => setState(() => year--),
        year >= app.today.date.year ? null : () => setState(() => year++),
      ),
      const SizedBox(height: 12),
      Text(s.yearCalendarHint, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      SectionTitle(
        s.habitLogs,
        count: counts.values.fold<int>(0, (a, b) => a + b),
        tone: UiTone.violet,
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var m = 1; m <= 12; m++)
            AppAction(
              key: Key('calendar-month-$m'),
              label:
                  '${DateFormat.MMM(Localizations.localeOf(context).languageCode).format(DateTime(year, m))}  ${counts.entries.where((e) => e.key.date.month == m).fold<int>(0, (sum, e) => sum + e.value)}',
              primary: calendarMonth == m,
              tone: UiTone.violet,
              onTap: () => setState(() => calendarMonth = m),
            ),
        ],
      ),
      const SizedBox(height: 18),
      MonthRecordGrid(
        year: year,
        month: calendarMonth,
        today: app.today,
        counts: counts,
        onDay: (d) => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DayHistoryPage(app: app, day: d, habitId: habitId),
          ),
        ),
      ),
    ];
  }

  List<Widget> events(BuildContext context) {
    final s = AppLocalizations.of(context);
    final start = timelineDay ?? month;
    final end =
        timelineDay ?? Day(DateTime(month.date.year, month.date.month + 1, 0));
    final items = timeline(
      from: start,
      through: end,
      today: app.today,
      habits: app.habits,
      plans: app.plans,
      entries: app.entries,
      tasks: app.tasks,
      taskEntries: app.taskEntries,
      notes: app.notes,
      cards: app.cards,
      kind: timelineKind,
    );
    return [
      period(
        context,
        DateFormat.yMMMM(
          Localizations.localeOf(context).languageCode,
        ).format(month.date),
        month.date.year <= 1900 && month.date.month == 1
            ? null
            : () => setState(() {
                month = Day(DateTime(month.date.year, month.date.month - 1));
                timelineDay = null;
              }),
        month.date.year == app.today.date.year &&
                month.date.month == app.today.date.month
            ? null
            : () => setState(() {
                month = Day(DateTime(month.date.year, month.date.month + 1));
                timelineDay = null;
              }),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AppAction(
            label: s.allEvents,
            primary: timelineKind == null,
            onTap: () => setState(() => timelineKind = null),
          ),
          for (final k in TimelineKind.values)
            AppAction(
              label: timelineLabel(s, k),
              primary: timelineKind == k,
              tone: UiTone.violet,
              onTap: () => setState(() => timelineKind = k),
            ),
        ],
      ),
      if (timelineDay != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: AppAction(
            label: '${timelineDay!.key} · ${s.showWholeMonth}',
            icon: Icons.close_rounded,
            onTap: () => setState(() => timelineDay = null),
          ),
        ),
      const SizedBox(height: 12),
      Text(s.timelineHint, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 16),
      if (items.isEmpty)
        EmptyState(
          icon: Icons.timeline_rounded,
          title: s.noTimeline,
          body: s.noTimelineHint,
          tone: UiTone.violet,
        ),
      for (final e in items) TimelineTile(app: app, event: e),
    ];
  }
}

class QuantityTrend extends StatelessWidget {
  const QuantityTrend({
    super.key,
    required this.points,
    required this.unit,
    required this.app,
    required this.habit,
  });
  final List<QuantityPoint> points;
  final String unit;
  final AppController app;
  final Habit habit;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final total = points.fold<int>(0, (sum, p) => sum + p.value);
    final max = points.fold<int>(
      1,
      (peak, p) => p.value > peak ? p.value : peak,
    );
    return SoftPanel(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            unit.isEmpty ? s.noUnit : unit,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${s.quantitySum} ${quantityText(total)}\n${s.recordedAverage} ${quantityText((total + points.length ~/ 2) ~/ points.length)}\n${s.recordedDays} ${points.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Text(s.trendScrollHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final p in points)
                  Semantics(
                    label: '${p.day.key}, ${quantityText(p.value)} $unit',
                    button: true,
                    child: InkWell(
                      onTap: () => correctRecord(context, app, habit, p.day),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SizedBox(
                          width: 72,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                quantityText(p.value),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 22,
                                height: 4 + 76 * p.value / max,
                                decoration: BoxDecoration(
                                  color: UiTone.blue.ink(context),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${p.day.date.month}/${p.day.date.day}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MonthRecordGrid extends StatelessWidget {
  const MonthRecordGrid({
    super.key,
    required this.year,
    required this.month,
    required this.today,
    required this.counts,
    required this.onDay,
  });
  final int year, month;
  final Day today;
  final Map<Day, int> counts;
  final ValueChanged<Day> onDay;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final first = DateTime(year, month);
    final offset = first.weekday - 1;
    final length = DateTime(year, month + 1, 0).day;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final cell = 48.0 * scale;
    return SoftPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMM(
              Localizations.localeOf(context).languageCode,
            ).format(first),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 7 * cell,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final label in [
                        s.weekMon,
                        s.weekTue,
                        s.weekWed,
                        s.weekThu,
                        s.weekFri,
                        s.weekSat,
                        s.weekSun,
                      ])
                        SizedBox(
                          width: cell,
                          height: 36 * scale,
                          child: Center(child: Text(label)),
                        ),
                    ],
                  ),
                  for (var row = 0; row < (offset + length + 6) ~/ 7; row++)
                    Row(
                      children: [
                        for (var col = 0; col < 7; col++)
                          Builder(
                            builder: (context) {
                              final n = row * 7 + col - offset + 1;
                              if (n < 1 || n > length) {
                                return SizedBox(width: cell, height: cell);
                              }
                              final d = Day(DateTime(year, month, n));
                              final count = counts[d] ?? 0;
                              final future = d.compareTo(today) > 0;
                              return SizedBox(
                                width: cell,
                                height: cell,
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Semantics(
                                    label:
                                        '${d.key}, ${s.habitLogs} $count${future ? ', ${s.futureDate}' : ''}',
                                    button: !future,
                                    onTap: future ? null : () => onDay(d),
                                    child: ExcludeSemantics(
                                      child: Material(
                                        color: future
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.surface
                                            : count == 0
                                            ? UiTone.blue.wash(context)
                                            : UiTone.violet
                                                  .ink(context)
                                                  .withValues(
                                                    alpha: (.08 + .035 * count)
                                                        .clamp(.08, .25),
                                                  ),
                                        borderRadius: BorderRadius.circular(10),
                                        child: InkWell(
                                          key: Key('calendar-${d.key}'),
                                          onTap: future ? null : () => onDay(d),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$n',
                                                style: TextStyle(
                                                  color: future
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.outline
                                                      : Theme.of(
                                                          context,
                                                        ).colorScheme.onSurface,
                                                  fontWeight: count > 0
                                                      ? FontWeight.w700
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                              if (count > 0)
                                                Container(
                                                  width: 4,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String timelineLabel(AppLocalizations s, TimelineKind kind) => switch (kind) {
  TimelineKind.habit => s.habit,
  TimelineKind.task => s.tasks,
  TimelineKind.note => s.notes,
  TimelineKind.card => s.cardCollection,
};

class TimelineTile extends StatelessWidget {
  const TimelineTile({super.key, required this.app, required this.event});
  final AppController app;
  final TimelineEvent event;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final e = event;
    final epoch = app.generation;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftPanel(
        padding: EdgeInsets.zero,
        child: SettingRow(
          icon: switch (e.kind) {
            TimelineKind.habit => Icons.fact_check_outlined,
            TimelineKind.task => Icons.checklist_rounded,
            TimelineKind.note => Icons.edit_note_rounded,
            TimelineKind.card => Icons.style_outlined,
          },
          tone: e.kind == TimelineKind.task ? UiTone.peach : UiTone.violet,
          title: e.kind == TimelineKind.card
              ? cardTitle(s, int.parse(e.title))
              : e.title.length > 100
              ? '${e.title.substring(0, 100)}…'
              : e.title,
          subtitle:
              '${dateLabel(context, e.day)} · ${timelineLabel(s, e.kind)}${e.resident ? ' (${s.residentTask})' : ''}${e.value == null ? '' : '\n${e.unit == null ? (e.value == 1000 ? s.finished : s.notCompleted) : '${quantityText(e.value!)} ${e.unit}'}'}',
          onTap: () {
            switch (e.kind) {
              case TimelineKind.habit:
                final h = app.habits.where((h) => h.id == e.id).firstOrNull;
                if (h != null) correctRecord(context, app, h, e.day);
              case TimelineKind.task:
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => e.resident
                        ? ResidentTaskPage(
                            app: app,
                            id: e.id,
                            initialDay: e.day,
                          )
                        : OneTimeTaskPage(app: app, id: e.id),
                  ),
                );
              case TimelineKind.note:
                final n = app.notes.where((n) => n.id == e.id).firstOrNull;
                if (n != null) {
                  openEditor(
                    context,
                    app,
                    'note',
                    note: n,
                    expectedGeneration: epoch,
                  );
                }
              case TimelineKind.card:
                openCard(context, app, e.day);
            }
          },
        ),
      ),
    );
  }
}

class DayHistoryPage extends StatelessWidget {
  const DayHistoryPage({
    super.key,
    required this.app,
    required this.day,
    this.habitId,
  });
  final AppController app;
  final Day day;
  final String? habitId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final items =
          timeline(
            from: day,
            through: day,
            today: app.today,
            habits: app.habits,
            plans: app.plans,
            entries: app.entries,
            tasks: app.tasks,
            taskEntries: app.taskEntries,
            notes: app.notes,
            cards: app.cards,
          ).where(
            (e) =>
                habitId == null ||
                (e.kind == TimelineKind.habit && e.id == habitId),
          );
      final missing = app.habits.where(
        (h) =>
            (habitId == null || h.id == habitId) &&
            day.compareTo(h.startDay) >= 0 &&
            !app.entries.any((e) => e.habitId == h.id && e.day == day),
      );
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(dateLabel(context, day))),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                s.timelineHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (items.isEmpty) Text(s.noTimeline),
              for (final e in items) TimelineTile(app: app, event: e),
              if (missing.isNotEmpty) ...[
                const SizedBox(height: 20),
                SectionTitle(s.noRecordHabits, tone: UiTone.violet),
                for (final h in missing)
                  SettingRow(
                    icon: Icons.circle_outlined,
                    title: h.title,
                    subtitle: stateLabel(s, statsFor(app, h).state(day)),
                    onTap: () => correctRecord(context, app, h, day),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
