import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'statistics.dart';
import 'insights.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key, required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final days = List.generate(7, (i) => app.today.plus(i - 6));
      final counts = days
          .map((d) => app.entries.where((e) => e.day == d).length)
          .toList();
      final taskCounts = days.map(app.tasksCompletedOn).toList();
      final max = counts.fold<int>(1, (a, b) => a > b ? a : b);
      final hasActivity =
          counts.any((n) => n > 0) ||
          taskCounts.any((n) => n > 0) ||
          app.notes.any((n) => days.contains(n.day)) ||
          app.cards.any((c) => days.contains(c.day));
      void openDay(Day day) => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DayHistoryPage(app: app, day: day),
        ),
      );
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.review)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!hasActivity)
                EmptyState(
                  key: const Key('review-empty'),
                  icon: Icons.history_rounded,
                  title: s.pmReviewEmptyTitle,
                  body: s.pmReviewEmptyBody,
                  tone: UiTone.violet,
                ),
              if (hasActivity)
                SoftPanel(
                  tinted: true,
                  tone: UiTone.violet,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppBadge(
                        '${MaterialLocalizations.of(context).formatShortDate(days.first.date)} – ${MaterialLocalizations.of(context).formatShortDate(days.last.date)}',
                        tone: UiTone.violet,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 32,
                        runSpacing: 16,
                        children: [
                          _metric(
                            context,
                            s.habitLogs,
                            counts.fold<int>(0, (a, b) => a + b),
                            UiTone.violet,
                          ),
                          _metric(
                            context,
                            s.taskCompletions,
                            taskCounts.fold<int>(0, (a, b) => a + b),
                            UiTone.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ExcludeSemantics(
                        child: SizedBox(
                          height:
                              128 +
                              64 *
                                  (MediaQuery.textScalerOf(context).scale(1) -
                                          1)
                                      .clamp(0.0, 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < 7; i++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${counts[i]}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 7),
                                        Container(
                                          height: 8 + 72 * counts[i] / max,
                                          width: 24,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            gradient: LinearGradient(
                                              colors: i == 6
                                                  ? [
                                                      const Color(0xFF6F9AFF),
                                                      const Color(0xFF1656DF),
                                                    ]
                                                  : [
                                                      UiTone.violet
                                                          .ink(context)
                                                          .withValues(
                                                            alpha: .3,
                                                          ),
                                                      UiTone.violet
                                                          .ink(context)
                                                          .withValues(
                                                            alpha: .65,
                                                          ),
                                                    ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          DateFormat.E(
                                            Localizations.localeOf(
                                              context,
                                            ).languageCode,
                                          ).format(days[i].date),
                                          maxLines: 1,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Text(s.reviewBody, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              AppAction(
                label: s.statisticsTitle,
                icon: Icons.insights_outlined,
                tone: UiTone.violet,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => StatisticsPage(app: app),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SectionTitle(s.history, tone: UiTone.violet),
              SoftPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 6; i >= 0; i--) ...[
                      SettingRow(
                        key: Key('review-day-${days[i].key}'),
                        icon: Icons.calendar_today_outlined,
                        title: MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(days[i].date),
                        subtitle:
                            '${s.habitLogs} ${counts[i]} · ${s.taskCompletions} ${taskCounts[i]}',
                        tone: UiTone.violet,
                        onTap: () => openDay(days[i]),
                      ),
                      if (i > 0) const Divider(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                key: const Key('review-insights-bridge'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => InsightsPage(app: app),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
                child: SoftPanel(
                  tone: UiTone.violet,
                  tinted: true,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: UiTone.violet
                              .ink(context)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_graph_rounded,
                          size: 20,
                          color: UiTone.violet.ink(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Localizations.localeOf(context).languageCode ==
                                      'zh'
                                  ? '✦ Plus 深度洞察 · 多周期规律'
                                  : '✦ Plus Deep Insights · Long-term Rhythm',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: UiTone.violet.ink(context),
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Localizations.localeOf(context).languageCode ==
                                      'zh'
                                  ? '想要洞悉哪一天最容易放弃、哪两个习惯总是一起完成？前往深度洞察 >'
                                  : 'Discover your peak days, weak points & habit pairs >',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: UiTone.violet.ink(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  Widget _metric(BuildContext context, String label, int value, UiTone tone) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: tone.ink(context)),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
