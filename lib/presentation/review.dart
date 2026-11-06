import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/app_controller.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'statistics.dart';

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
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.review)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
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
                                (MediaQuery.textScalerOf(context).scale(1) - 1)
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
                                                        .withValues(alpha: .3),
                                                    UiTone.violet
                                                        .ink(context)
                                                        .withValues(alpha: .65),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(days[i].date),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                AppBadge(
                                  '${s.habitLogs}  ${counts[i]}',
                                  tone: UiTone.violet,
                                ),
                                AppBadge(
                                  '${s.taskCompletions}  ${taskCounts[i]}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (i > 0) const Divider(),
                    ],
                  ],
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
