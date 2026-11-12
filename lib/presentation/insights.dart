import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../application/app_controller.dart';
import '../domain/insights.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'plus_page.dart';
import 'refined_components.dart';
import 'theme.dart';

/// Plus-only view over a closed historical window. The report itself is pure
/// and lives in lib/domain/insights.dart; this page only presents it.
class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key, required this.app});

  final AppController app;

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int _days = 30;

  AppController get app => widget.app;

  InsightReport _report() {
    final today = app.today;
    return buildInsightReport(
      habits: app.habits,
      plans: app.plans,
      activity: app.activity,
      entries: app.entries,
      breaks: app.rests,
      notes: app.notes,
      tasks: app.tasks,
      taskEntries: app.taskEntries,
      events: app.events,
      today: today,
      start: today.plus(-_days),
      end: today,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: app.plus,
      builder: (context, _) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final report = _report();
          return AppCanvas(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(title: Text(s.insightsTitle)),
              body: SafeArea(
                top: false,
                child: app.plus.enabled
                    ? _Unlocked(
                        s: s,
                        days: _days,
                        report: report,
                        onRange: (days) => setState(() => _days = days),
                      )
                    : _Locked(s: s, app: app),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Unlocked extends StatelessWidget {
  const _Unlocked({
    required this.s,
    required this.days,
    required this.report,
    required this.onRange,
  });

  final AppLocalizations s;
  final int days;
  final InsightReport report;
  final ValueChanged<int> onRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      key: const PageStorageKey('insights'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in const [30, 90, 365])
              QuietChoice(
                key: Key('insights-range-$preset'),
                label: switch (preset) {
                  30 => s.insightsRange30,
                  90 => s.insightsRange90,
                  _ => s.insightsRange365,
                },
                selected: days == preset,
                tone: UiTone.violet,
                onTap: () => onRange(preset),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(s.insightsSubtitle, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        if (report.empty)
          EmptyState(
            icon: Icons.auto_graph_rounded,
            title: s.insightsEmptyTitle,
            body: s.insightsEmptyBody,
            tone: UiTone.violet,
          )
        else ...[
          _Summary(s: s, days: days, report: report),
          if (report.weekdays.any((w) => w.due > 0)) ...[
            SectionTitle(s.insightsWeekdayTitle, tone: UiTone.teal),
            _Weekdays(s: s, report: report),
          ],
          if (report.habits.isNotEmpty) ...[
            SectionTitle(s.insightsHabitsTitle, tone: UiTone.violet),
            _HabitRows(s: s, habits: report.habits),
          ],
          if (report.weeklyHabits.isNotEmpty) ...[
            SectionTitle(s.insightsWeeklyTitle, tone: UiTone.sky),
            _WeeklyRows(s: s, habits: report.weeklyHabits),
          ],
          if (report.pairs.isNotEmpty) ...[
            SectionTitle(s.insightsPairsTitle, tone: UiTone.rose),
            _Pairs(s: s, pairs: report.pairs),
          ],
          if (report.journal.notes > 0 || report.events > 0) ...[
            SectionTitle(s.insightsJournalTitle, tone: UiTone.peach),
            _Journal(s: s, report: report),
          ],
          if (report.months.isNotEmpty) ...[
            SectionTitle(s.insightsMonthsTitle, tone: UiTone.violet),
            _Months(s: s, report: report),
          ],
        ],
        const SizedBox(height: 18),
        Text(
          s.insightsThrough(_dayLabel(context, report.end)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.s, required this.app});

  final AppLocalizations s;
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final sample = sampleInsightReport(app.today, isZh);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        SoftPanel(
          tinted: true,
          tone: UiTone.violet,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ToneIcon(Icons.auto_graph_rounded, tone: UiTone.violet, size: 48),
              const SizedBox(height: 14),
              Text(
                s.insightsLockedTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                s.insightsLockedBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isZh
                          ? '一次买断 · 享后续全部 Plus 新功能免费升级'
                          : 'Lifetime Access · Includes all future Plus updates',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppAction(
                key: const Key('insights-unlock'),
                label: s.insightsUnlock,
                icon: Icons.auto_awesome_rounded,
                primary: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => PlusPage(app: app)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionTitle(
          isZh ? '深度洞察效果演示 (样例报表)' : 'Insights Demo Preview (Sample)',
          tone: UiTone.violet,
        ),
        const SizedBox(height: 4),
        Text(
          isZh
              ? '开通 Plus 后，系统将在本地离线挖掘属于您的真实习惯节律与数据规律：'
              : 'Once unlocked, insights are computed locally from your real check-in history:',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        _Summary(s: s, days: 30, report: sample),
        SectionTitle(s.insightsWeekdayTitle, tone: UiTone.teal),
        _Weekdays(s: s, report: sample),
        SectionTitle(s.insightsHabitsTitle, tone: UiTone.violet),
        _HabitRows(s: s, habits: sample.habits),
        SectionTitle(s.insightsPairsTitle, tone: UiTone.rose),
        _Pairs(s: s, pairs: sample.pairs),
        const SizedBox(height: 20),
        SoftPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.update_rounded,
                    size: 20,
                    color: UiTone.violet.ink(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isZh ? '持续迭代优化与升级承诺' : 'Continuous Evolution & Updates',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isZh
                    ? 'DayPanel 坚持纯本地私密、零广告、零云端上传。Plus 采用终身买断制：未来版本中持续增加的所有深度洞察新维度、桌面小部件与专属装扮，终身会员均永久免费享有，绝无二次收费或隐藏订阅。'
                    : 'DayPanel commits to 100% offline privacy, zero ads, and no cloud uploads. Plus is a true lifetime license: all future analytical views, widget layouts, and premium styles will be free updates for lifetime members.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              AppAction(
                label: isZh ? '查看 Plus 完整权益' : 'Explore All Plus Benefits',
                tone: UiTone.violet,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => PlusPage(app: app)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

InsightReport sampleInsightReport(Day today, bool isZh) {
  final start = today.plus(-30);
  final end = today.plus(-1);
  return InsightReport(
    start: start,
    end: end,
    due: 75,
    done: 66,
    perfectDays: 18,
    activeDays: 28,
    previousDue: 75,
    previousDone: 59,
    habits: [
      HabitInsight(
        habitId: 'demo-reading',
        title: isZh ? '晨间阅读 20 页' : 'Morning Reading 20p',
        due: 30,
        done: 28,
        currentStreak: 21,
        bestStreak: 21,
        previousDue: 30,
        previousDone: 24,
      ),
      HabitInsight(
        habitId: 'demo-water',
        title: isZh ? '每天喝水 2000ml' : 'Hydration 2000ml',
        due: 30,
        done: 26,
        currentStreak: 12,
        bestStreak: 19,
        previousDue: 30,
        previousDone: 22,
      ),
      HabitInsight(
        habitId: 'demo-run',
        title: isZh ? '户外慢跑 3 公里' : 'Morning Run 3km',
        due: 15,
        done: 12,
        currentStreak: 4,
        bestStreak: 7,
        previousDue: 15,
        previousDone: 13,
      ),
    ],
    weeklyHabits: const [],
    weekdays: const [
      WeekdayInsight(weekday: 1, due: 12, done: 11),
      WeekdayInsight(weekday: 2, due: 12, done: 12),
      WeekdayInsight(weekday: 3, due: 11, done: 10),
      WeekdayInsight(weekday: 4, due: 11, done: 10),
      WeekdayInsight(weekday: 5, due: 11, done: 9),
      WeekdayInsight(weekday: 6, due: 9, done: 8),
      WeekdayInsight(weekday: 7, due: 9, done: 6),
    ],
    pairs: [
      HabitPairInsight(
        aId: 'demo-reading',
        aTitle: isZh ? '晨间阅读 20 页' : 'Morning Reading 20p',
        bId: 'demo-water',
        bTitle: isZh ? '每天喝水 2000ml' : 'Hydration 2000ml',
        together: 24,
        commonDue: 30,
        expected: 24.2,
        lift: 1.15,
      ),
    ],
    journal: const JournalInsight(notes: 14, days: 12, characters: 1680),
    events: 36,
    months: const [],
    bestStreak: 21,
    bestStreakHabit: isZh ? '晨间阅读 20 页' : 'Morning Reading 20p',
    strongestWeekday: 2,
    weakestWeekday: 7,
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.s, required this.days, required this.report});

  final AppLocalizations s;
  final int days;
  final InsightReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftPanel(
      tinted: true,
      tone: UiTone.violet,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.insightsRate, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                report.due == 0 ? '—' : _percent(report.rate),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TrendChip(
                  s: s,
                  trend: report.trend,
                  delta: report.delta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            report.delta == null
                ? s.insightsNoComparison
                : s.insightsVsPrevious(days),
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 26),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: '${report.perfectDays}',
                  label: s.insightsPerfectDays,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  value: '${report.activeDays}',
                  label: s.insightsActiveDays,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: '${report.journal.notes}',
                  label: s.insightsNotes,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  value: '${report.bestStreak}',
                  label: s.insightsBestStreak,
                  note: report.bestStreakHabit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.note});

  final String value, label;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
        if (note != null)
          Text(
            note!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
      ],
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.s, required this.trend, required this.delta});

  final AppLocalizations s;
  final InsightTrend trend;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    final change = delta;
    if (change == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final (tone, icon, label) = switch (trend) {
      InsightTrend.up => (
        UiTone.teal,
        Icons.trending_up_rounded,
        s.insightsTrendUp,
      ),
      InsightTrend.down => (
        UiTone.rose,
        Icons.trending_down_rounded,
        s.insightsTrendDown,
      ),
      InsightTrend.steady => (
        UiTone.blue,
        Icons.trending_flat_rounded,
        s.insightsTrendSteady,
      ),
    };
    final value = _percent(change.abs());
    return Semantics(
      label: '$label $value',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tone.wash(context),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: tone.ink(context)),
            const SizedBox(width: 3),
            Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tone.ink(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Weekdays extends StatelessWidget {
  const _Weekdays({required this.s, required this.report});

  final AppLocalizations s;
  final InsightReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          for (final day in report.weekdays)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      _shortWeekday(s, day.weekday),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  Expanded(
                    child: _RateBar(
                      rate: day.rate,
                      tone: day.weekday == report.strongestWeekday
                          ? UiTone.teal
                          : day.weekday == report.weakestWeekday
                          ? UiTone.rose
                          : UiTone.violet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 42,
                    child: Text(
                      day.due == 0 ? '—' : _percent(day.rate),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(s.insightsWeekdayHint, style: theme.textTheme.bodySmall),
          if (report.strongestWeekday != null ||
              report.weakestWeekday != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (report.strongestWeekday != null)
                  s.insightsStrongestLine(
                    _fullWeekday(s, report.strongestWeekday!),
                  ),
                if (report.weakestWeekday != null)
                  s.insightsWeakestLine(
                    _fullWeekday(s, report.weakestWeekday!),
                  ),
              ].join('  ·  '),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _HabitRows extends StatelessWidget {
  const _HabitRows({required this.s, required this.habits});

  final AppLocalizations s;
  final List<HabitInsight> habits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        children: [
          for (var i = 0; i < habits.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habits[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${s.insightsHabitMeta(habits[i].done, habits[i].due)}'
                              ' · '
                              '${s.insightsStreakDays(habits[i].currentStreak)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _percent(habits[i].rate),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _TrendChip(
                            s: s,
                            trend: habits[i].trend,
                            delta: habits[i].delta,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _RateBar(
                    rate: habits[i].rate,
                    tone: switch (habits[i].trend) {
                      InsightTrend.up => UiTone.teal,
                      InsightTrend.down => UiTone.rose,
                      InsightTrend.steady => UiTone.violet,
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyRows extends StatelessWidget {
  const _WeeklyRows({required this.s, required this.habits});

  final AppLocalizations s;
  final List<WeeklyHabitInsight> habits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        children: [
          for (var i = 0; i < habits.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habits[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        _percent(habits[i].rate),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${s.insightsWeeklyMeta(habits[i].doneWeeks, habits[i].dueWeeks)}'
                    ' · '
                    '${s.insightsWeeklyStreak(habits[i].currentStreak)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _RateBar(rate: habits[i].rate, tone: UiTone.sky),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pairs extends StatelessWidget {
  const _Pairs({required this.s, required this.pairs});

  final AppLocalizations s;
  final List<HabitPairInsight> pairs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = pairs.take(4).toList();
    return SoftPanel(
      tinted: true,
      tone: UiTone.rose,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            Text(
              '${shown[i].aTitle}  ×  ${shown[i].bTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              '${s.insightsPairTogether(shown[i].together)}'
              ' · '
              '${s.insightsPairLift(shown[i].liftPercent)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(s.insightsPairsHint, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Journal extends StatelessWidget {
  const _Journal({required this.s, required this.report});

  final AppLocalizations s;
  final InsightReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journal = report.journal;
    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            journal.notes == 0
                ? s.insightsJournalEmpty
                : s.insightsJournalSummary(
                    journal.notes,
                    journal.characters,
                    journal.days,
                  ),
            style: theme.textTheme.bodyMedium,
          ),
          if (report.events > 0) ...[
            const SizedBox(height: 6),
            Text(
              s.insightsEventCount(report.events),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Months extends StatelessWidget {
  const _Months({required this.s, required this.report});

  final AppLocalizations s;
  final InsightReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final month in report.months)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Tooltip(
                        message:
                            '${month.year}-${month.month}: '
                            '${month.done}/${month.due}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  widthFactor: .7,
                                  heightFactor: month.rate.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: UiTone.violet
                                          .ink(context)
                                          .withValues(alpha: .72),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${month.month}',
                              maxLines: 1,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${report.months.first.year}–${report.months.last.year}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RateBar extends StatelessWidget {
  const _RateBar({required this.rate, this.tone = UiTone.violet});

  final double rate;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: .38);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LayoutBuilder(
        builder: (context, constraints) => Container(
          height: 8,
          color: track,
          alignment: Alignment.centerLeft,
          child: Container(
            width: constraints.maxWidth * rate.clamp(0.0, 1.0),
            height: 8,
            color: tone.ink(context),
          ),
        ),
      ),
    );
  }
}

String _percent(double value) => '${(value * 100).round()}%';

String _dayLabel(BuildContext context, Day day) => DateFormat.yMMMd(
  Localizations.localeOf(context).languageCode,
).format(day.date);

String _shortWeekday(AppLocalizations s, int day) => switch (day) {
  1 => s.weekMon,
  2 => s.weekTue,
  3 => s.weekWed,
  4 => s.weekThu,
  5 => s.weekFri,
  6 => s.weekSat,
  _ => s.weekSun,
};

String _fullWeekday(AppLocalizations s, int day) => switch (day) {
  1 => s.weekMonFull,
  2 => s.weekTueFull,
  3 => s.weekWedFull,
  4 => s.weekThuFull,
  5 => s.weekFriFull,
  6 => s.weekSatFull,
  _ => s.weekSunFull,
};
