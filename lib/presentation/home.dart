import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'editors.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.app});
  final AppController app;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int tab = 0;
  Timer? timer;
  late Day lastToday;
  AppController get app => widget.app;
  @override
  void initState() {
    super.initState();
    lastToday = app.today;
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refreshDate());
  }

  void refreshDate() {
    final now = app.today;
    if (now != lastToday) {
      if (app.selectedDay == lastToday) app.select(now);
      lastToday = now;
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshDate();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final titles = [s.today, s.tasks, s.notes, s.mine];
      return Scaffold(
        appBar: AppBar(
          title: Text(titles[tab]),
          actions: [
            if (tab == 0)
              IconButton(
                tooltip: s.review,
                icon: const Icon(Icons.bar_chart_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => ReviewPage(app: app)),
                ),
              ),
            if (tab < 3)
              IconButton.filled(
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                tooltip: [s.newHabit, s.newTask, s.newNote][tab],
                onPressed: app.busy
                    ? null
                    : () => openEditor(
                        context,
                        app,
                        ['habit', 'task', 'note'][tab],
                      ),
                icon: const Icon(Icons.add),
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (app.busy) const LinearProgressIndicator(minHeight: 2),
              if (app.error != null)
                MaterialBanner(
                  content: Text(s.storageError),
                  actions: [
                    TextButton(
                      onPressed: app.busy ? null : () => app.run(() async {}),
                      child: Text(s.retry),
                    ),
                    TextButton(
                      onPressed: app.acknowledgeError,
                      child: Text(s.cancel),
                    ),
                  ],
                ),
              Expanded(
                child: switch (tab) {
                  0 => daily(context),
                  1 => taskList(context),
                  2 => journal(context),
                  _ => preferences(context),
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.wb_sunny_outlined),
              selectedIcon: const Icon(Icons.wb_sunny_rounded),
              label: s.today,
            ),
            NavigationDestination(
              icon: const Icon(Icons.checklist_rounded),
              label: s.tasks,
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_stories_outlined),
              label: s.notes,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              label: s.mine,
            ),
          ],
        ),
      );
    },
  );

  Widget daily(BuildContext context) {
    final s = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final day = app.selectedDay;
    final planned = app.planned;
    final anyActive = app.habits.any((h) => !h.archived);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(s.dailyHeading, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(s.dailySubtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                MaterialLocalizations.of(context).formatMonthYear(day.date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (day != app.today)
              TextButton(
                onPressed: () => app.select(app.today),
                child: Text(s.goToday),
              ),
            IconButton(
              tooltip: s.chooseDate,
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: day.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) app.select(Day(d));
              },
            ),
          ],
        ),
        SizedBox(
          height:
              90 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = day.plus(i - (day.date.weekday - 1));
              final selected = d == day;
              final label = DateFormat.E(
                Localizations.localeOf(context).languageCode,
              ).format(d.date);
              return SizedBox(
                width:
                    48 *
                    MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5),
                child: Semantics(
                  label: MaterialLocalizations.of(
                    context,
                  ).formatFullDate(d.date),
                  selected: selected,
                  child: Material(
                    color: selected
                        ? scheme.primary
                        : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => app.select(d),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${d.date.day}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        if (planned.isNotEmpty)
          SoftPanel(
            tinted: true,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planned.isNotEmpty && app.completed == planned.length
                            ? s.allDone
                            : s.planned,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${app.completed} / ${planned.length}  ${s.habitCount}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.progressHint,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox.square(
                  dimension: 50,
                  child: CircularProgressIndicator(
                    value: planned.isEmpty ? 0 : app.completed / planned.length,
                    strokeWidth: 5,
                    backgroundColor: scheme.primary.withValues(alpha: 0.09),
                    semanticsLabel:
                        '${s.planned} ${app.completed}/${planned.length}',
                  ),
                ),
              ],
            ),
          ),
        if (planned.isNotEmpty) const SizedBox(height: 24),
        if (planned.isEmpty)
          EmptyState(
            icon: Icons.spa_outlined,
            title: anyActive ? s.emptyDay : s.emptyHabits,
            body: anyActive ? s.emptyDayBody : s.emptyHabitsBody,
            action: s.newHabit,
            onAction: () => openEditor(context, app, 'habit'),
          ),
        for (final h in planned)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitTile(app: app, habit: h, day: day),
          ),
        if (app.habits.any(
          (h) => !h.archived && !h.scheduled(day) && app.value(h, day) != null,
        )) ...[
          const SizedBox(height: 12),
          Text(s.extraRecords, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final h in app.habits.where(
            (h) =>
                !h.archived && !h.scheduled(day) && app.value(h, day) != null,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HabitTile(app: app, habit: h, day: day),
            ),
        ],
      ],
    );
  }

  Widget taskList(BuildContext context) {
    final s = AppLocalizations.of(context);
    final today = app.today;
    final groups = <(String, List<SmallTask>)>[
      (
        s.todayLabel,
        app.tasks.where((t) => !t.done && t.dueDay == today).toList(),
      ),
      (
        s.overdue,
        app.tasks
            .where(
              (t) =>
                  !t.done && t.dueDay != null && t.dueDay!.compareTo(today) < 0,
            )
            .toList(),
      ),
      (s.inbox, app.tasks.where((t) => !t.done && t.dueDay == null).toList()),
      (
        s.upcoming,
        app.tasks
            .where(
              (t) =>
                  !t.done && t.dueDay != null && t.dueDay!.compareTo(today) > 0,
            )
            .toList(),
      ),
      (
        s.completedToday,
        app.tasks.where((t) => t.completedDay == today).toList(),
      ),
      (
        s.completedEarlier,
        app.tasks.where((t) => t.done && t.completedDay != today).toList(),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (app.tasks.isEmpty)
          EmptyState(
            icon: Icons.checklist_rounded,
            title: s.emptyTasks,
            body: s.emptyTasksBody,
            action: s.newTask,
            onAction: () => openEditor(context, app, 'task'),
          ),
        for (final group in groups)
          if (group.$2.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Text(
                '${group.$1} (${group.$2.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final task in group.$2)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftPanel(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: task.done ? s.reopen : s.done,
                        onPressed: app.busy
                            ? null
                            : () => app.run(
                                () => app.store.completeTask(
                                  task.id,
                                  !task.done,
                                  app.today,
                                ),
                              ),
                        icon: Icon(
                          task.done
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: task.done
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: app.busy
                              ? null
                              : () => openEditor(
                                  context,
                                  app,
                                  'task',
                                  task: task,
                                ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        decoration: task.done
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  task.dueDay == null
                                      ? s.noDate
                                      : MaterialLocalizations.of(
                                          context,
                                        ).formatMediumDate(task.dueDay!.date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: s.more,
                        onSelected: (action) async {
                          if (action == 'edit' && context.mounted) {
                            await openEditor(context, app, 'task', task: task);
                          }
                          if (action == 'delete' &&
                              context.mounted &&
                              await confirmDelete(context)) {
                            await app.run(
                              () => app.store.remove('tasks', task.id),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(s.edit)),
                          PopupMenuItem(value: 'delete', child: Text(s.delete)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
      ],
    );
  }

  Widget journal(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (app.notes.isEmpty)
          EmptyState(
            icon: Icons.edit_note_rounded,
            title: s.emptyNotes,
            body: s.emptyNotesBody,
            action: s.newNote,
            onAction: () => openEditor(context, app, 'note'),
          ),
        for (final note in app.notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SoftPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatFullDate(note.day.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: s.more,
                        onSelected: (action) async {
                          if (action == 'edit' && context.mounted) {
                            await openEditor(context, app, 'note', note: note);
                          }
                          if (action == 'delete' &&
                              context.mounted &&
                              await confirmDelete(context)) {
                            await app.run(
                              () => app.store.remove('notes', note.id),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(s.edit)),
                          PopupMenuItem(value: 'delete', child: Text(s.delete)),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => openEditor(context, app, 'note', note: note),
                    child: Text(
                      note.body,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget preferences(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SoftPanel(
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.spa_outlined, size: 36),
              const SizedBox(height: 16),
              Text(s.freeTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(s.freeBody),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.grid_view_rounded),
          title: Text(s.manageHabits),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => HabitLibrary(app: app)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.bar_chart_rounded),
          title: Text(s.review),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => ReviewPage(app: app)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(s.appearance),
          subtitle: Text(switch (app.preferences['theme']) {
            'light' => s.light,
            'dark' => s.dark,
            _ => s.system,
          }),
          onTap: () => preferencePicker(context, 'theme', {
            'system': s.system,
            'light': s.light,
            'dark': s.dark,
          }),
        ),
        ListTile(
          leading: const Icon(Icons.translate_rounded),
          title: Text(s.language),
          subtitle: Text(switch (app.preferences['locale']) {
            'zh' => s.chinese,
            'en' => s.english,
            _ => s.system,
          }),
          onTap: () => preferencePicker(context, 'locale', {
            'system': s.system,
            'zh': s.chinese,
            'en': s.english,
          }),
        ),
        const SizedBox(height: 20),
        SoftPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.localData, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(s.localDataBody),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.code_rounded),
          title: Text(s.licenses),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'DayPanel',
            applicationVersion: '0.1.0-dev',
          ),
        ),
      ],
    );
  }

  Future<void> preferencePicker(
    BuildContext context,
    String key,
    Map<String, String> choices,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          key == 'theme'
              ? AppLocalizations.of(ctx).appearance
              : AppLocalizations.of(ctx).language,
        ),
        children: choices.entries
            .map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, e.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.value)),
                      if ((app.preferences[key] ?? 'system') == e.key)
                        const Icon(Icons.check),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      await app.run(() => app.store.preference(key, selected));
    }
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title, body;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(
            icon,
            size: 36,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        if (action != null)
          FilledButton.tonal(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

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
    final amount = app.value(habit, day);
    final done = app.achieved(habit, day);
    final enabled =
        !app.busy &&
        !habit.archived &&
        day.compareTo(app.today) <= 0 &&
        day.compareTo(habit.startDay) >= 0;
    final scheme = Theme.of(context).colorScheme;
    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  habitIcons[habit.icon],
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                habit.kind == HabitKind.quantity
                    ? '${amount == null ? '—' : quantityText(amount)} / ${quantityText(habit.target)} ${habit.unit}'
                    : (done
                          ? s.finished
                          : amount == null
                          ? s.notRecorded
                          : s.notCompleted),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              FilledButton.tonal(
                onPressed: enabled
                    ? () {
                        if (habit.kind == HabitKind.quantity) {
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
                child: Text(
                  habit.kind == HabitKind.quantity
                      ? s.record
                      : done
                      ? s.reopen
                      : s.done,
                ),
              ),
            ],
          ),
          if (habit.kind == HabitKind.quantity) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ((amount ?? 0) / habit.target).clamp(0.0, 1.0),
                minHeight: 5,
              ),
            ),
          ],
          if (day.compareTo(app.today) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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
      return Scaffold(
        appBar: AppBar(
          title: Text(s.manageHabits),
          actions: [
            IconButton(
              tooltip: s.newHabit,
              onPressed: () => openEditor(context, app, 'habit'),
              icon: const Icon(Icons.add),
            ),
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
                Text(
                  archived ? s.archived : s.active,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final h in app.habits.where((h) => h.archived == archived))
                  ListTile(
                    leading: Icon(habitIcons[h.icon]),
                    title: Text(h.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => HabitDetails(app: app, id: h.id),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
          ],
        ),
      );
    },
  );
}

class HabitDetails extends StatefulWidget {
  const HabitDetails({super.key, required this.app, required this.id});
  final AppController app;
  final String id;
  @override
  State<HabitDetails> createState() => _HabitDetailsState();
}

class _HabitDetailsState extends State<HabitDetails> {
  Day? selected;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final app = widget.app;
      final matches = app.habits.where((h) => h.id == widget.id);
      if (matches.isEmpty) return const Scaffold(body: SizedBox.shrink());
      final h = matches.first;
      final s = AppLocalizations.of(context);
      final day = selected ?? app.today;
      return Scaffold(
        appBar: AppBar(
          title: Text(h.title),
          actions: [
            IconButton(
              tooltip: s.edit,
              onPressed: app.busy
                  ? null
                  : () => openEditor(context, app, 'habit', habit: h),
              icon: const Icon(Icons.edit_outlined),
            ),
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
                    MaterialLocalizations.of(context).formatFullDate(day.date),
                  ),
                ),
                IconButton(
                  tooltip: s.chooseDate,
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: day.date,
                      firstDate: h.startDay.date,
                      lastDate: app.today.date,
                    );
                    if (d != null && mounted) setState(() => selected = Day(d));
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ],
            ),
            HabitTile(app: app, habit: h, day: day, openDetails: false),
            const SizedBox(height: 24),
            Text(s.history, style: Theme.of(context).textTheme.titleLarge),
            for (var i = 0; i < 7; i++)
              if (app.today.plus(-i).compareTo(h.startDay) >= 0)
                ListTile(
                  title: Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(app.today.plus(-i).date),
                  ),
                  trailing: Text(
                    app.value(h, app.today.plus(-i)) == null
                        ? s.notRecorded
                        : h.kind == HabitKind.quantity
                        ? '${quantityText(app.value(h, app.today.plus(-i))!)} ${h.unit}'
                        : app.achieved(h, app.today.plus(-i))
                        ? s.finished
                        : s.notCompleted,
                  ),
                  onTap: () => setState(() => selected = app.today.plus(-i)),
                ),
            const SizedBox(height: 20),
            Text(s.archivedHint),
            TextButton.icon(
              onPressed: app.busy
                  ? null
                  : () =>
                        app.run(() => app.store.setArchived(h.id, !h.archived)),
              icon: const Icon(Icons.archive_outlined),
              label: Text(h.archived ? s.unarchive : s.archive),
            ),
            TextButton.icon(
              onPressed: app.busy
                  ? null
                  : () async {
                      if (!await confirmDelete(context, habit: true)) return;
                      final ok = await app.run(
                        () => app.store.remove('habits', h.id),
                      );
                      if (ok && context.mounted) Navigator.pop(context);
                    },
              icon: const Icon(Icons.delete_outline),
              label: Text(s.delete),
            ),
          ],
        ),
      );
    },
  );
}

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
      final max = counts.fold<int>(1, (a, b) => a > b ? a : b);
      return Scaffold(
        appBar: AppBar(title: Text(s.review)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(s.reviewBody),
            const SizedBox(height: 24),
            for (var i = 0; i < days.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(days[i].date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: counts[i] / max,
                        minHeight: 5,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          Text('${s.habitLogs}  ${counts[i]}'),
                          Text(
                            '${s.taskCompletions}  ${app.tasks.where((t) => t.completedDay == days[i]).length}',
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
    },
  );
}
