import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../application/app_controller.dart';
import '../domain/habit_templates.dart';
import '../domain/models.dart';
import '../domain/record_event.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'editors.dart';
import 'theme.dart';
import 'habit_icon.dart';
import 'organization.dart';
import 'reminders.dart';
import 'journal.dart';
import 'card_art.dart';
import 'heatmap.dart';
import 'statistics.dart';
import 'refined_components.dart';
import 'rest_days.dart';
import 'record_events.dart';
import '../domain/habit_break.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.app,
    required this.habit,
    required this.day,
    this.openDetails = true,
  });
  final AppController app;
  final Habit habit;
  final Day day;
  final bool openDetails;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final epoch = app.generation;
    final display = app.forDay(habit, day);
    final plan = app.planAt(habit, day);
    final amount = plan.schedule == ScheduleKind.weeklyTotal
        ? app.weekTotal(habit, day)
        : app.value(habit, day);
    final done = app.achieved(habit, day);
    final rest = app.restOn(habit, day);
    final tone = habitTone(habit.icon, habit.color);
    final enabled =
        !app.busy &&
        !habit.archived &&
        rest == null &&
        day.compareTo(app.today) <= 0 &&
        day.compareTo(habit.startDay) >= 0;
    final scheme = Theme.of(context).colorScheme;
    final isQuantity = habit.kind.isNumeric;
    if (openDetails) {
      void details() => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HabitDetails(app: app, id: habit.id, initialDay: day),
        ),
      );
      void record() {
        if (rest != null && day != app.today) {
          details();
        } else if (rest != null) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => RestDaysPage(app: app, id: habit.id),
            ),
          );
        } else if (isQuantity) {
          openQuantity(context, app, habit, day);
        } else {
          app.recordHabit(habit, day, done ? null : 1000, epoch);
        }
      }

      final quickStep = habit.kind == HabitKind.count
          ? 1000
          : ((display.unit.toLowerCase() == 'ml' || display.unit == '毫升') &&
                    display.target >= 1000000
                ? 250000
                : (quantityIncrementSuggestions(
                        display.target,
                        display.unit,
                        wholeCounts: false,
                      ).firstOrNull ??
                      (display.target % 1000 == 0 && display.target <= 10000
                          ? 1000
                          : (display.target ~/ 4 > 0
                                ? display.target ~/ 4
                                : 1000))));
      final stepText = quantityText(quickStep);
      final quickLabel = habit.kind == HabitKind.count
          ? '+1'
          : '+$stepText${display.unit.isNotEmpty && display.unit.length <= 4 ? display.unit : ''}';
      void quickAdd() {
        if (!enabled) return;
        final current = app.value(habit, day) ?? 0;
        final next = current + quickStep;
        final capped = next > 999999999999 ? 999999999999 : next;
        if (app.plus.enabled && day == app.today) {
          final now = app.clock();
          final event = RecordEvent(
            id: const Uuid().v4(),
            habitId: habit.id,
            day: day,
            value: quickStep,
            minute: now.hour * 60 + now.minute,
          );
          app.recordIndividual(event, epoch);
        } else {
          app.recordHabit(habit, day, capped, epoch);
        }
      }

      final label = rest != null
          ? s.restTitle
          : isQuantity
          ? s.record
          : done
          ? s.reopen
          : s.done;
      final subtitle = rest != null
          ? restName(s, rest)
          : isQuantity
          ? '${amount == null ? '—' : quantityText(amount)} / ${quantityText(display.target)} ${display.unit}'
          : done
          ? s.finished
          : s.notRecorded;
      final action = AppAction(
        key: Key('habit-action-${habit.id}'),
        label: label,
        icon: isQuantity
            ? Icons.edit_outlined
            : done
            ? Icons.undo_rounded
            : Icons.check_rounded,
        tone: tone,
        onTap: rest != null || enabled ? record : null,
      );
      final quickAction = Semantics(
        button: true,
        label: quickLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('habit-quick-add-${habit.id}'),
            borderRadius: BorderRadius.circular(14),
            onTap: rest != null || enabled ? quickAdd : null,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: tone.wash(context),
                border: Border.all(
                  color: tone.ink(context).withValues(alpha: .2),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: tone.ink(context)),
                  const SizedBox(width: 4),
                  Text(
                    quickLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tone.ink(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return RepaintBoundary(
        child: SoftPanel(
          key: Key('habit-card-${habit.id}'),
          radius: 18,
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, c) {
              final stacked =
                  c.maxWidth < (isQuantity ? 390 : 280) ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: rest != null || enabled
                            ? (isQuantity ? quickAdd : record)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: HabitIcon(
                          habit.icon,
                          color: habit.color,
                          frame: habit.frame,
                          size: 44,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: details,
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  habit.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: rest != null
                                            ? UiTone.violet.ink(context)
                                            : tone.ink(context),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!stacked)
                        isQuantity
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  quickAction,
                                  const SizedBox(width: 6),
                                  action,
                                ],
                              )
                            : ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 128,
                                ),
                                child: action,
                              )
                      else
                        IconButton(
                          tooltip: s.history,
                          onPressed: details,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                    ],
                  ),
                  if (stacked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: isQuantity
                            ? Wrap(
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 6,
                                children: [quickAction, action],
                              )
                            : action,
                      ),
                    ),
                  if (plan.schedule.isWeekly)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        plan.schedule == ScheduleKind.weeklyTotal
                            ? '${s.weeklyTotalProgress} ${quantityText(app.weekTotal(habit, day))} / ${quantityText(plan.target)} ${plan.unit}'
                            : '${s.weekProgress} ${app.weekCount(habit, day)} / ${plan.weeklyGoal}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (isQuantity)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(
                        value: ((amount ?? 0) / display.target).clamp(0.0, 1.0),
                        minHeight: 3,
                        color: tone.ink(context),
                        backgroundColor: tone.wash(context),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
    }
    return RepaintBoundary(
      child: SoftPanel(
        tinted: done,
        tone: tone,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HabitIcon(
                  habit.icon,
                  color: habit.color,
                  size: 46,
                  frame: habit.frame,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: openDetails
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => HabitDetails(
                                app: app,
                                id: habit.id,
                                initialDay: day,
                              ),
                            ),
                          )
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${contextName(s, habit.context)} · ${habit.kind == HabitKind.count
                                ? s.countHabit
                                : isQuantity
                                ? s.quantityHabit
                                : s.checkHabit}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (openDetails)
                  IconButton(
                    tooltip: s.history,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => HabitDetails(
                          app: app,
                          id: habit.id,
                          initialDay: day,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                if (isQuantity)
                  RichText(
                    textScaler: MediaQuery.textScalerOf(context),
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: amount == null ? '—' : quantityText(amount),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: tone.ink(context),
                          ),
                        ),
                        TextSpan(
                          text:
                              ' / ${quantityText(display.target)} ${display.unit}',
                        ),
                      ],
                    ),
                  )
                else
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    transitionBuilder: cardFlipTransition,
                    child: AppBadge(
                      done
                          ? s.finished
                          : amount == null
                          ? s.notRecorded
                          : s.notCompleted,
                      tone: done ? tone : UiTone.blue,
                      key: ValueKey(done),
                      icon: done ? Icons.done_rounded : Icons.circle_outlined,
                    ),
                  ),
                if (rest != null)
                  AppBadge(restName(s, rest), tone: UiTone.violet),
                AppAction(
                  key: Key('habit-detail-action-${habit.id}'),
                  label: rest != null
                      ? s.restTitle
                      : isQuantity
                      ? s.record
                      : done
                      ? s.reopen
                      : s.done,
                  icon: isQuantity
                      ? Icons.edit_outlined
                      : done
                      ? Icons.undo_rounded
                      : Icons.check_rounded,
                  tone: tone,
                  onTap: rest != null
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                RestDaysPage(app: app, id: habit.id),
                          ),
                        )
                      : enabled
                      ? () {
                          if (isQuantity) {
                            openQuantity(context, app, habit, day);
                          } else {
                            app.recordHabit(
                              habit,
                              day,
                              done ? null : 1000,
                              epoch,
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
            if (isQuantity) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ((amount ?? 0) / display.target).clamp(0.0, 1.0),
                  minHeight: 5,
                  color: tone.ink(context),
                  backgroundColor: tone.wash(context),
                ),
              ),
            ],
            if (plan.schedule.isWeekly) ...[
              const SizedBox(height: 12),
              AppBadge(
                plan.schedule == ScheduleKind.weeklyTotal
                    ? '${s.weeklyTotalProgress} ${quantityText(app.weekTotal(habit, day))} / ${quantityText(plan.target)} ${plan.unit}'
                    : '${s.weekProgress} ${app.weekCount(habit, day)} / ${plan.weeklyGoal}',
                tone: UiTone.violet,
              ),
              if (plan.effectiveDay.compareTo(day.monday) > 0) ...[
                const SizedBox(height: 6),
                Text(
                  s.partialWeek,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
            if (day.compareTo(app.today) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  s.futureDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HabitLibrary extends StatelessWidget {
  const HabitLibrary({super.key, required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.manageHabits),
            actions: [
              AppIconAction(
                icon: Icons.add,
                label: s.newHabit,
                onTap: () => openEditor(context, app, 'habit'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SoftPanel(
                padding: const EdgeInsets.all(4),
                tinted: true,
                tone: UiTone.violet,
                child: Column(
                  children: [
                    SettingRow(
                      icon: Icons.folder_outlined,
                      title: s.manageGroups,
                      tone: UiTone.violet,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => GroupsPage(app: app),
                        ),
                      ),
                    ),
                    if (app.habits.length > 1)
                      SettingRow(
                        icon: Icons.sort_rounded,
                        title: s.sortHabits,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => HabitOrderPage(app: app),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (app.error != null)
                Text(
                  s.storageError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (app.habits.isEmpty)
                EmptyState(
                  icon: Icons.spa_outlined,
                  title: s.emptyHabits,
                  body: s.emptyHabitsBody,
                  action: s.newHabit,
                  onAction: () => openEditor(context, app, 'habit'),
                ),
              for (final archived in [false, true])
                if (app.habits.any((h) => h.archived == archived)) ...[
                  SectionTitle(
                    archived ? s.archived : s.active,
                    count: app.habits
                        .where((h) => h.archived == archived)
                        .length,
                    tone: archived ? UiTone.violet : UiTone.blue,
                  ),
                  for (final h in app.habits.where(
                    (h) => h.archived == archived,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftPanel(
                        padding: const EdgeInsets.all(2),
                        child: SettingRow(
                          leading: HabitIcon(
                            h.icon,
                            color: h.color,
                            frame: h.frame,
                            size: 40,
                          ),
                          icon: habitIcons[h.icon],
                          title: h.title,
                          tone: habitTone(h.icon, h.color),
                          subtitle: h.kind.isNumeric
                              ? '${quantityText(h.target)} ${h.unit}'
                              : s.checkHabit,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<HabitManagementResult>(
                              builder: (_) =>
                                  HabitManagementPage(app: app, id: h.id),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
      );
    },
  );
}

class HabitDetails extends StatefulWidget {
  const HabitDetails({
    super.key,
    required this.app,
    required this.id,
    this.initialDay,
    this.logOnOpen = false,
  });
  final AppController app;
  final String id;
  final Day? initialDay;
  final bool logOnOpen;
  @override
  State<HabitDetails> createState() => _HabitDetailsState();
}

class _HabitDetailsState extends State<HabitDetails> {
  late Day selected;
  late final int epoch;
  bool history = false;
  @override
  void initState() {
    super.initState();
    selected = widget.initialDay ?? widget.app.today;
    epoch = widget.app.generation;
    if (widget.logOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || epoch != widget.app.generation) return;
        final h = widget.app.habits
            .where((h) => h.id == widget.id && !h.archived)
            .firstOrNull;
        if (h != null && h.kind.isNumeric) {
          openQuantity(context, widget.app, h, selected);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final app = widget.app;
      final s = AppLocalizations.of(context);
      final h = app.habits.where((h) => h.id == widget.id).firstOrNull;
      if (h == null || epoch != app.generation) {
        return HabitUnavailable(changed: epoch != app.generation);
      }
      final day = selected;
      final plan = app.planAt(h, day);
      final rest = app.restOn(h, day);
      final valid =
          day.compareTo(h.startDay) >= 0 && day.compareTo(app.today) <= 0;
      final maySkip =
          !h.archived &&
          valid &&
          app.value(h, day) == null &&
          rest == null &&
          plan.scheduled(day);
      Future<void> manage() async {
        final navigator = Navigator.of(this.context);
        final origin = ModalRoute.of(this.context);
        final result = await navigator.push<HabitManagementResult>(
          MaterialPageRoute<HabitManagementResult>(
            builder: (_) =>
                HabitManagementPage(app: app, id: h.id, noteDay: day),
          ),
        );
        if (!mounted || result != HabitManagementResult.deleted) return;
        if (origin?.isCurrent == true && navigator.canPop()) {
          navigator.pop();
        }
      }

      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(h.title),
            actions: [
              IconButton(
                key: const Key('habit-settings'),
                tooltip: s.habitSettings,
                icon: const Icon(Icons.tune_rounded),
                onPressed: manage,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatFullDate(day.date),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    key: const Key('habit-record-date'),
                    tooltip: s.chooseDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: h.startDay.compareTo(app.today) > 0
                        ? null
                        : () async {
                            final bounded = day.compareTo(h.startDay) < 0
                                ? h.startDay
                                : day.compareTo(app.today) > 0
                                ? app.today
                                : day;
                            final d = await showDatePicker(
                              context: context,
                              initialDate: bounded.date,
                              firstDate: h.startDay.date,
                              lastDate: app.today.date,
                            );
                            if (d != null && mounted) {
                              setState(() => selected = Day(d));
                            }
                          },
                  ),
                ],
              ),
              if (app.error != null)
                Text(
                  s.storageError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (!history) ...[
                if (h.archived)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(s.restoreToCorrect),
                  ),
                if (h.archived || rest != null)
                  SoftPanel(
                    key: const Key('readonly-habit-record'),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.archived ? s.archived : restName(s, rest!),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (h.kind.isNumeric)
                          Text(
                            '${app.value(h, day) == null ? '—' : quantityText(app.value(h, day)!)} / ${quantityText(plan.target)} ${plan.unit}',
                          )
                        else
                          Text(
                            app.achieved(h, day)
                                ? s.finished
                                : app.value(h, day) == null
                                ? s.notRecorded
                                : s.notCompleted,
                          ),
                      ],
                    ),
                  )
                else
                  HabitTile(app: app, habit: h, day: day, openDetails: false),
                if (rest != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      restRecordHint(s, rest, day, app.today),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (!h.archived &&
                    valid &&
                    (maySkip || rest?.kind == BreakKind.skip))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('skip-record-day'),
                      icon: const Icon(Icons.skip_next_outlined),
                      label: Text(rest == null ? s.restSkip : s.restUnskip),
                      onPressed: app.busy
                          ? null
                          : () => skipDay(context, app, h, day),
                    ),
                  ),
                const SizedBox(height: 12),
                if (h.kind.isNumeric)
                  SettingRow(
                    key: const Key('habit-events'),
                    icon: Icons.receipt_long_outlined,
                    title: s.eventTitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            RecordEventsPage(app: app, habitId: h.id, day: day),
                      ),
                    ),
                  ),
                SettingRow(
                  key: const Key('habit-record-history'),
                  icon: Icons.history_rounded,
                  title: s.recordHistory,
                  tone: UiTone.violet,
                  onTap: () => setState(() => history = true),
                ),
                if (app.notes.any((n) => n.habitId == h.id))
                  SettingRow(
                    icon: Icons.auto_stories_outlined,
                    title: s.viewHabitNotes,
                    subtitle:
                        '${app.notes.where((n) => n.habitId == h.id).length}',
                    tone: UiTone.violet,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            HabitJournalPage(app: app, habitId: h.id),
                      ),
                    ),
                  ),
              ] else ...[
                TextButton.icon(
                  key: const Key('back-to-record'),
                  onPressed: () => setState(() => history = false),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(s.recordSelectedDay),
                ),
                AppAction(
                  label: s.habitStatistics,
                  icon: Icons.insights_outlined,
                  tone: UiTone.violet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => StatisticsPage(
                        app: app,
                        habitId: h.id,
                        initialTab: 1,
                        initialDay: day,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ActivityHeatmap(
                  today: app.today,
                  title: s.habitHeatmapTitle,
                  subtitle: s.activityHeatmapSubtitle,
                  tone: habitTone(h.icon, h.color),
                  initialSelectedDay: day,
                  levelForDay: (d) {
                    if (d.compareTo(h.startDay) < 0 ||
                        d.compareTo(app.today) > 0) {
                      return 0;
                    }
                    if (app.restOn(h, d) != null) return 0;
                    if (!h.kind.isNumeric) {
                      return app.achieved(h, d)
                          ? 3
                          : (app.value(h, d) != null ? 1 : 0);
                    }
                    final val = app.value(h, d);
                    if (val == null || val == 0) return 0;
                    final target = app.planAt(h, d).target;
                    if (target <= 0) return 3;
                    final ratio = val / target;
                    if (ratio < 0.5) return 1;
                    if (ratio < 1.0) return 2;
                    return 3;
                  },
                  detailForDay: (d) {
                    if (app.restOn(h, d) != null) {
                      return restName(s, app.restOn(h, d)!);
                    }
                    final val = app.value(h, d);
                    if (val == null) return s.notRecorded;
                    if (h.kind.isNumeric) {
                      final plan = app.planAt(h, d);
                      return '${quantityText(val)} / ${quantityText(plan.target)} ${plan.unit}';
                    }
                    return app.achieved(h, d) ? s.finished : s.notCompleted;
                  },
                  onDayTap: (d) => setState(() {
                    selected = d;
                  }),
                ),
                const SizedBox(height: 16),
                SectionTitle(s.history, tone: habitTone(h.icon, h.color)),
                for (var i = 0; i < 7; i++)
                  if (day.plus(-i).compareTo(h.startDay) >= 0)
                    SettingRow(
                      key: Key('habit-history-${day.plus(-i).key}'),
                      icon: Icons.calendar_today_outlined,
                      title: MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(day.plus(-i).date),
                      subtitle: app.restOn(h, day.plus(-i)) != null
                          ? restName(s, app.restOn(h, day.plus(-i))!)
                          : app.value(h, day.plus(-i)) == null
                          ? s.notRecorded
                          : h.kind.isNumeric
                          ? '${quantityText(app.value(h, day.plus(-i))!)} ${app.planAt(h, day.plus(-i)).unit}'
                          : app.achieved(h, day.plus(-i))
                          ? s.finished
                          : s.notCompleted,
                      onTap: () => setState(() {
                        selected = day.plus(-i);
                        history = false;
                      }),
                    ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class HabitUnavailable extends StatelessWidget {
  const HabitUnavailable({super.key, required this.changed});
  final bool changed;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.manageHabits)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              EmptyState(
                key: const Key('habit-unavailable'),
                icon: Icons.info_outline_rounded,
                title: changed ? s.contextChanged : s.habitUnavailable,
                body: s.reopenContext,
                action: s.back,
                actionIcon: Icons.arrow_back_rounded,
                onAction: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum HabitManagementResult { deleted }

/// Whole-habit choices are deliberately separate from a day's recording flow.
class HabitManagementPage extends StatefulWidget {
  const HabitManagementPage({
    super.key,
    required this.app,
    required this.id,
    this.noteDay,
  });
  final AppController app;
  final String id;
  final Day? noteDay;
  @override
  State<HabitManagementPage> createState() => _HabitManagementPageState();
}

class _HabitManagementPageState extends State<HabitManagementPage> {
  late final int epoch;
  @override
  void initState() {
    super.initState();
    epoch = widget.app.generation;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final app = widget.app;
      final s = AppLocalizations.of(context);
      final h = app.habits.where((h) => h.id == widget.id).firstOrNull;
      if (h == null || epoch != app.generation) {
        return HabitUnavailable(changed: epoch != app.generation);
      }
      final day = widget.noteDay ?? app.today;
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.habitSettings)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(h.title, style: Theme.of(context).textTheme.titleLarge),
              if (app.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    s.storageError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SettingRow(
                key: const Key('edit-habit-settings'),
                icon: Icons.edit_outlined,
                title: s.edit,
                onTap: app.busy
                    ? null
                    : () => openEditor(
                        context,
                        app,
                        'habit',
                        habit: h,
                        expectedGeneration: epoch,
                      ),
              ),
              SettingRow(
                icon: Icons.notifications_none_rounded,
                title: s.habitReminder,
                subtitle: h.archived
                    ? s.reminderArchived
                    : app.reminderFor(h.id).enabled
                    ? formatReminderTimes(
                        context,
                        app.reminderFor(h.id).minutes,
                      )
                    : s.reminderOff,
                tone: UiTone.peach,
                onTap: h.archived || app.busy
                    ? null
                    : () => openReminderEditor(context, app, h),
              ),
              if (!h.archived)
                SettingRow(
                  key: const Key('manage-rest-days'),
                  icon: Icons.free_breakfast_outlined,
                  title: s.restTitle,
                  subtitle: s.restManagementHint,
                  tone: UiTone.violet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => RestDaysPage(app: app, id: h.id),
                    ),
                  ),
                ),
              DetailDisclosure(
                title: s.habitJournal,
                subtitle: s.optionalHabitNotes,
                icon: Icons.edit_note_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppAction(
                      key: const Key('add-habit-note'),
                      label: s.writeHabitNote,
                      icon: Icons.edit_note_rounded,
                      onTap: app.busy
                          ? null
                          : () => openEditor(
                              context,
                              app,
                              'note',
                              noteHabitId: h.id,
                              noteDay: day,
                              expectedGeneration: epoch,
                            ),
                    ),
                    const SizedBox(height: 8),
                    AppAction(
                      label: s.viewHabitNotes,
                      icon: Icons.auto_stories_outlined,
                      tone: UiTone.violet,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              HabitJournalPage(app: app, habitId: h.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DetailDisclosure(
                title: s.planHistory,
                icon: Icons.event_note_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (app.pending(h) != null)
                      AppBadge(s.planPending, tone: UiTone.peach),
                    for (final p
                        in app.plans
                            .where((p) => p.habitId == h.id)
                            .toList()
                            .reversed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.effectiveFrom} ${p.effectiveDay.key}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(scheduleText(s, p)),
                            if (h.kind.isNumeric)
                              Text(
                                '${p.schedule == ScheduleKind.weeklyTotal ? s.weeklyTargetAmount : s.target} ${quantityText(p.target)} ${p.unit}',
                              ),
                          ],
                        ),
                      ),
                    if (!app.activity.any(
                      (a) => a.habitId == h.id && a.day == h.startDay,
                    ))
                      Text(
                        s.planVersionNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                s.archivedHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              AppAction(
                label: h.archived ? s.unarchive : s.archive,
                icon: Icons.archive_outlined,
                tone: UiTone.violet,
                onTap: app.busy
                    ? null
                    : () => app.run(
                        () => app.store.setArchived(
                          h.id,
                          !h.archived,
                          today: app.today,
                        ),
                        expectedGeneration: epoch,
                      ),
              ),
              const SizedBox(height: 10),
              AppAction(
                label: s.delete,
                icon: Icons.delete_outline,
                danger: true,
                onTap: app.busy
                    ? null
                    : () async {
                        final navigator = Navigator.of(this.context);
                        final origin = ModalRoute.of(this.context);
                        if (!await confirmDelete(this.context, habit: true) ||
                            !mounted) {
                          return;
                        }
                        final ok = await app.run(
                          () => app.store.remove('habits', h.id),
                          expectedGeneration: epoch,
                        );
                        if (ok &&
                            mounted &&
                            origin?.isCurrent == true &&
                            navigator.canPop()) {
                          navigator.pop(HabitManagementResult.deleted);
                        }
                      },
              ),
            ],
          ),
        ),
      );
    },
  );
}
