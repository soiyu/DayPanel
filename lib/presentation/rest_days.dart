import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../application/app_controller.dart';
import '../data/app_store.dart';
import '../domain/models.dart';
import '../domain/habit_break.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'refined_components.dart';

String restName(AppLocalizations s, HabitBreak rest) => switch (rest.kind) {
  BreakKind.pause => s.restPaused,
  BreakKind.vacation => s.restVacation,
  BreakKind.skip => s.restSkipped,
};

Future<void> skipDay(
  BuildContext context,
  AppController app,
  Habit h,
  Day day,
) async {
  final epoch = app.generation;
  final s = AppLocalizations.of(context);
  final old = app.restOn(h, day);
  final rest = HabitBreak(
    id: const Uuid().v4(),
    habitId: h.id,
    start: day,
    end: day,
    kind: BreakKind.skip,
  );
  final yes = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SheetFrame(
      title: old == null ? s.restSkip : s.restUnskip,
      subtitle: MaterialLocalizations.of(ctx).formatFullDate(day.date),
      icon: Icons.free_breakfast_outlined,
      tone: UiTone.violet,
      body: Text(old == null ? s.restConfirmSkip : s.restConfirmUnskip),
      footer: Row(
        children: [
          Expanded(
            child: AppAction(
              label: s.cancel,
              onTap: () => Navigator.pop(ctx, false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppAction(
              label: s.save,
              primary: true,
              onTap: () => Navigator.pop(ctx, true),
            ),
          ),
        ],
      ),
    ),
  );
  if (yes != true) return;
  await app.run(
    () => old == null
        ? app.store.addBreak(rest, today: app.today)
        : app.store.endBreak(old, today: app.today),
    expectedGeneration: epoch,
  );
}

class RestDaysPage extends StatefulWidget {
  const RestDaysPage({super.key, required this.app, required this.id});
  final AppController app;
  final String id;
  @override
  State<RestDaysPage> createState() => _RestDaysPageState();
}

class _RestDaysPageState extends State<RestDaysPage> {
  AppController get app => widget.app;
  String get id => widget.id;
  late final int epoch;
  String? localError;
  @override
  void initState() {
    super.initState();
    epoch = app.generation;
  }

  Future<void> pause(BuildContext context) async {
    final today = app.today;
    final s = AppLocalizations.of(context);
    final yes = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => SheetFrame(
        title: s.restPause,
        icon: Icons.pause_circle_outline,
        body: Text(s.restHint),
        footer: Row(
          children: [
            Expanded(
              child: AppAction(
                label: s.cancel,
                onTap: () => Navigator.pop(ctx, false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppAction(
                label: s.save,
                primary: true,
                onTap: () => Navigator.pop(ctx, true),
              ),
            ),
          ],
        ),
      ),
    );
    if (yes != true) return;
    await app.run(
      () => app.store.addBreak(
        HabitBreak(
          id: const Uuid().v4(),
          habitId: id,
          start: today,
          kind: BreakKind.pause,
        ),
        today: app.today,
      ),
      expectedGeneration: epoch,
    );
  }

  Future<void> vacation(BuildContext context) async {
    final today = app.today;
    final s = AppLocalizations.of(context);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today.date,
      lastDate: DateTime(2200, 12, 31),
      initialDateRange: DateTimeRange(
        start: today.date,
        end: today.plus(6).date,
      ),
      helpText: s.restRange,
    );
    if (range == null) return;
    if (!mounted) return;
    if (Day(range.end).daysSince(Day(range.start)) >= 365) {
      setState(() => localError = s.restRangeLimit);
      return;
    }
    setState(() => localError = null);
    await app.run(
      () => app.store.addBreak(
        HabitBreak(
          id: const Uuid().v4(),
          habitId: id,
          start: Day(range.start),
          end: Day(range.end),
          kind: BreakKind.vacation,
        ),
        today: app.today,
      ),
      expectedGeneration: epoch,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final h = app.habits.where((h) => h.id == id).firstOrNull;
      final rows = app.rests.where((b) => b.habitId == id).toList()
        ..sort((a, b) => b.start.compareTo(a.start));
      final current = h == null ? null : app.restOn(h, app.today);
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.restTitle)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (h != null)
                Text(h.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(s.restHint),
              const SizedBox(height: 20),
              if (h == null || epoch != app.generation)
                Text(s.restStale)
              else if (!h.archived && current == null) ...[
                ActionTile(
                  key: const Key('pause-habit'),
                  title: s.restPause,
                  subtitle: s.restUntilResume,
                  icon: Icons.pause_circle_outline,
                  tone: UiTone.violet,
                  onTap: app.busy ? null : () => pause(context),
                ),
                const SizedBox(height: 12),
                ActionTile(
                  key: const Key('vacation-habit'),
                  title: s.restPlanVacation,
                  subtitle: s.restRangeLimit,
                  icon: Icons.date_range_outlined,
                  tone: UiTone.peach,
                  onTap: app.busy ? null : () => vacation(context),
                ),
              ],
              if (app.error != null || localError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    epoch != app.generation
                        ? s.restStale
                        : localError ?? s.restConflict,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (rows.isNotEmpty) SectionHeading(s.restSchedule),
              for (final rest in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SoftPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          restName(s, rest),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${rest.start.key} · ${rest.end?.key ?? s.restUntilResume}',
                        ),
                        const SizedBox(height: 10),
                        if (rest.end == null ||
                            rest.end!.compareTo(app.today) >= 0 ||
                            rest.kind == BreakKind.skip)
                          AppAction(
                            key: Key('end-rest-${rest.id}'),
                            label: rest.kind == BreakKind.skip
                                ? s.restUnskip
                                : rest.start.compareTo(app.today) > 0
                                ? s.restCancelFuture
                                : s.restResume,
                            onTap:
                                app.busy || epoch != app.generation || h == null
                                ? null
                                : () {
                                    app.run(
                                      () => app.store.endBreak(
                                        rest,
                                        today: app.today,
                                      ),
                                      expectedGeneration: epoch,
                                    );
                                  },
                          )
                        else
                          Text(
                            s.restEnded,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              DetailDisclosure(
                title: s.uiMoreDetails,
                child: Text(s.restRules),
              ),
            ],
          ),
        ),
      );
    },
  );
}
