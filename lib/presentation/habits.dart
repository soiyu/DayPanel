import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'editors.dart';
import 'theme.dart';
import 'organization.dart';
import 'reminders.dart';
import 'journal.dart';

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
    final display = app.forDay(habit, day);
    final plan = app.planAt(habit, day);
    final amount = app.value(habit, day);
    final done = app.achieved(habit, day);
    final tone = habitTone(habit.icon);
    final enabled =
        !app.busy &&
        !habit.archived &&
        day.compareTo(app.today) <= 0 &&
        day.compareTo(habit.startDay) >= 0;
    final scheme = Theme.of(context).colorScheme;
    final isQuantity = habit.kind == HabitKind.quantity;
    return SoftPanel(
      tinted: done,
      tone: tone,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToneIcon(habitIcons[habit.icon], tone: tone, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: openDetails
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                HabitDetails(app: app, id: habit.id),
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
                          '${contextName(s, habit.context)} · ${isQuantity ? s.quantityHabit : s.checkHabit}',
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
                      builder: (_) => HabitDetails(app: app, id: habit.id),
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
                    style: TextStyle(
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
                AppBadge(
                  done
                      ? s.finished
                      : amount == null
                      ? s.notRecorded
                      : s.notCompleted,
                  tone: done ? tone : UiTone.blue,
                  icon: done ? Icons.done_rounded : Icons.circle_outlined,
                ),
              AppAction(
                label: isQuantity
                    ? s.record
                    : done
                    ? s.reopen
                    : s.done,
                icon: isQuantity
                    ? Icons.add_rounded
                    : done
                    ? Icons.undo_rounded
                    : Icons.check_rounded,
                tone: tone,
                onTap: enabled
                    ? () {
                        if (isQuantity) {
                          openQuantity(context, app, habit, day);
                        } else {
                          app.run(
                            () => app.store.setRecord(
                              habit.id,
                              day,
                              done ? null : 1000,
                              today: app.today,
                            ),
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
          if (plan.schedule == ScheduleKind.weekly) ...[
            const SizedBox(height: 12),
            AppBadge(
              '${s.weekProgress} ${app.weekCount(habit, day)} / ${plan.weeklyGoal}',
              tone: UiTone.violet,
            ),
            if (plan.effectiveDay.compareTo(day.monday) > 0) ...[
              const SizedBox(height: 6),
              Text(s.partialWeek, style: Theme.of(context).textTheme.bodySmall),
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
                          icon: habitIcons[h.icon],
                          title: h.title,
                          tone: habitTone(h.icon),
                          subtitle: h.kind == HabitKind.quantity
                              ? '${quantityText(h.target)} ${h.unit}'
                              : s.checkHabit,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => HabitDetails(app: app, id: h.id),
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
    this.logOnOpen = false,
  });
  final AppController app;
  final String id;
  final bool logOnOpen;
  @override
  State<HabitDetails> createState() => _HabitDetailsState();
}

class _HabitDetailsState extends State<HabitDetails> {
  Day? selected;
  @override
  void initState() {
    super.initState();
    if (widget.logOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final h = widget.app.habits
            .where((h) => h.id == widget.id && !h.archived)
            .firstOrNull;
        if (h != null) openQuantity(context, widget.app, h, widget.app.today);
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final app = widget.app;
      final matches = app.habits.where((h) => h.id == widget.id);
      if (matches.isEmpty) return const Scaffold(body: SizedBox.shrink());
      final h = matches.first;
      final epoch = app.generation;
      final s = AppLocalizations.of(context);
      final day = selected ?? app.today;
      final tone = habitTone(h.icon);
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(h.title),
            actions: [
              AppIconAction(
                icon: Icons.edit_outlined,
                label: s.edit,
                tone: tone,
                onTap: app.busy
                    ? null
                    : () => openEditor(context, app, 'habit', habit: h),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (app.error != null)
                Text(
                  s.storageError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
                  AppIconAction(
                    label: s.chooseDate,
                    icon: Icons.calendar_month_outlined,
                    tone: UiTone.peach,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: day.date,
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
              const SizedBox(height: 16),
              HabitTile(app: app, habit: h, day: day, openDetails: false),
              const SizedBox(height: 16),
              SoftPanel(
                tinted: true,
                tone: UiTone.violet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle(
                      s.habitJournal,
                      count: app.notes.where((n) => n.habitId == h.id).length,
                      tone: UiTone.violet,
                    ),
                    Text(
                      s.noteAssociationHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppAction(
                          key: const Key('add-habit-note'),
                          label: s.writeHabitNote,
                          icon: Icons.edit_note_rounded,
                          primary: true,
                          onTap: app.busy
                              ? null
                              : () => openEditor(
                                  context,
                                  app,
                                  'note',
                                  noteHabitId: h.id,
                                  noteDay: day,
                                ),
                        ),
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
                    for (final note in app.notes.where(
                      (n) => n.habitId == h.id && n.day == day,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: NoteCard(app: app, note: note),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftPanel(
                padding: const EdgeInsets.all(3),
                tinted: true,
                tone: UiTone.peach,
                child: SettingRow(
                  icon: Icons.notifications_none_rounded,
                  title: s.habitReminder,
                  tone: UiTone.peach,
                  subtitle: widget.app.reminderFor(h.id).enabled
                      ? formatReminderTimes(
                          context,
                          widget.app.reminderFor(h.id).minutes,
                        )
                      : s.reminderOff,
                  onTap: () => openReminderEditor(context, app, h),
                ),
              ),
              if (app.pending(h) != null) ...[
                const SizedBox(height: 12),
                AppBadge(s.planPending, tone: UiTone.peach),
              ],
              const SizedBox(height: 24),
              SectionTitle(s.history, tone: tone),
              SoftPanel(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    for (var i = 0; i < 7; i++)
                      if (app.today.plus(-i).compareTo(h.startDay) >= 0)
                        SettingRow(
                          icon: Icons.calendar_today_outlined,
                          tone: tone,
                          title: MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(app.today.plus(-i).date),
                          subtitle: app.value(h, app.today.plus(-i)) == null
                              ? s.notRecorded
                              : h.kind == HabitKind.quantity
                              ? '${quantityText(app.value(h, app.today.plus(-i))!)} ${app.planAt(h, app.today.plus(-i)).unit}'
                              : app.achieved(h, app.today.plus(-i))
                              ? s.finished
                              : s.notCompleted,
                          trailing: day == app.today.plus(-i)
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: tone.ink(context),
                                  size: 20,
                                )
                              : null,
                          onTap: () =>
                              setState(() => selected = app.today.plus(-i)),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(s.planHistory, tone: UiTone.violet),
              for (final p
                  in app.plans
                      .where((p) => p.habitId == h.id)
                      .toList()
                      .reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftPanel(
                    tinted: true,
                    tone: UiTone.violet,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.effectiveFrom} ${p.effectiveDay.key}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(scheduleText(s, p)),
                        if (h.kind == HabitKind.quantity)
                          Text(
                            '${s.target} ${quantityText(p.target)} ${p.unit}',
                          ),
                      ],
                    ),
                  ),
                ),
              Text(
                s.planVersionNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text(
                s.archivedHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              AppAction(
                label: h.archived ? s.unarchive : s.archive,
                icon: Icons.archive_outlined,
                tone: UiTone.violet,
                onTap: app.busy
                    ? null
                    : () => app.run(
                        () => app.store.setArchived(h.id, !h.archived),
                        expectedGeneration: epoch,
                      ),
              ),
              const SizedBox(height: 12),
              AppAction(
                label: s.delete,
                icon: Icons.delete_outline,
                danger: true,
                onTap: app.busy
                    ? null
                    : () async {
                        if (!await confirmDelete(context, habit: true)) return;
                        final ok = await app.run(
                          () => app.store.remove('habits', h.id),
                          expectedGeneration: epoch,
                        );
                        if (ok && context.mounted) Navigator.pop(context);
                      },
              ),
            ],
          ),
        ),
      );
    },
  );
}
