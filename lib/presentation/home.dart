import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'editors.dart';
import 'habits.dart';
import 'review.dart';
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
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight: 60,
            titleSpacing: 20,
            title: Text(
              titles[tab],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            actions: [
              if (tab == 0)
                AppIconAction(
                  icon: Icons.bar_chart_rounded,
                  label: s.review,
                  tone: UiTone.violet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReviewPage(app: app),
                    ),
                  ),
                ),
              if (tab == 0) const SizedBox(width: 8),
              if (tab < 3)
                AppIconAction(
                  key: const Key('add-entry'),
                  icon: Icons.add,
                  label: [s.newHabit, s.newTask, s.newNote][tab],
                  primary: true,
                  onTap: app.busy
                      ? null
                      : () => openEditor(
                          context,
                          app,
                          ['habit', 'task', 'note'][tab],
                        ),
                ),
              const SizedBox(width: 20),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (app.busy) const LinearProgressIndicator(minHeight: 2),
                if (app.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SoftPanel(
                      tone: UiTone.peach,
                      tinted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.storageError),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: app.busy
                                    ? null
                                    : () => app.run(() async {}),
                                child: Text(s.retry),
                              ),
                              TextButton(
                                onPressed: app.acknowledgeError,
                                child: Text(s.cancel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
          bottomNavigationBar: GlassNavigation(
            index: tab,
            onSelected: (i) => setState(() => tab = i),
          ),
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
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return ListView(
      key: const PageStorageKey('daily'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          s.dailySubtitle,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            ToneIcon(
              Icons.calendar_today_rounded,
              tone: UiTone.peach,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                MaterialLocalizations.of(context).formatMonthYear(day.date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (day != app.today)
              TextButton(
                onPressed: () => app.select(app.today),
                child: Text(s.todayLabel),
              ),
            AppIconAction(
              label: s.chooseDate,
              icon: Icons.expand_more_rounded,
              tone: UiTone.peach,
              onTap: () async {
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
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cell =
                ((constraints.maxWidth - 6 * 5) / 7).clamp(48.0, 68.0) *
                scale.clamp(1.0, 1.5);
            return SizedBox(
              height: 70 * scale.clamp(1.0, 1.8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: 5),
                itemBuilder: (context, i) {
                  final d = day.plus(i - (day.date.weekday - 1));
                  final selected = d == day;
                  return SizedBox(
                    width: cell,
                    child: Semantics(
                      label: MaterialLocalizations.of(
                        context,
                      ).formatFullDate(d.date),
                      selected: selected,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(19),
                          onTap: () => app.select(d),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(19),
                              gradient: selected
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF407BF4),
                                        Color(0xFF1554DE),
                                      ],
                                    )
                                  : null,
                              color: selected
                                  ? null
                                  : scheme.surface.withValues(alpha: .5),
                              border: Border.all(
                                color: selected
                                    ? Colors.transparent
                                    : scheme.outlineVariant.withValues(
                                        alpha: .4,
                                      ),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat.E(
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ).format(d.date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected
                                        ? Colors.white.withValues(alpha: .85)
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${d.date.day}',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: d == app.today
                                        ? (selected
                                              ? Colors.white
                                              : scheme.primary)
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        if (planned.isNotEmpty) ...[
          SoftPanel(
            tinted: true,
            tone: UiTone.blue,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.completed == planned.length
                            ? s.allDone
                            : s.dailyCardTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${app.completed} / ${planned.length}  ${s.habitCount}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox.square(
                  dimension: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: app.completed / planned.length,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          backgroundColor: scheme.primary.withValues(alpha: .1),
                          semanticsLabel:
                              '${s.planned} ${app.completed}/${planned.length}',
                        ),
                      ),
                      Icon(
                        app.completed == planned.length
                            ? Icons.done_rounded
                            : Icons.spa_outlined,
                        color: scheme.primary,
                        size: 25,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(s.planned, count: planned.length),
        ],
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
          SectionTitle(s.extraRecords, tone: UiTone.violet),
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
    final groups = <(String, List<SmallTask>, UiTone)>[
      (
        s.todayLabel,
        app.tasks.where((t) => !t.done && t.dueDay == today).toList(),
        UiTone.blue,
      ),
      (
        s.overdue,
        app.tasks
            .where(
              (t) =>
                  !t.done && t.dueDay != null && t.dueDay!.compareTo(today) < 0,
            )
            .toList(),
        UiTone.peach,
      ),
      (
        s.inbox,
        app.tasks.where((t) => !t.done && t.dueDay == null).toList(),
        UiTone.violet,
      ),
      (
        s.upcoming,
        app.tasks
            .where(
              (t) =>
                  !t.done && t.dueDay != null && t.dueDay!.compareTo(today) > 0,
            )
            .toList(),
        UiTone.blue,
      ),
      (
        s.completedToday,
        app.tasks.where((t) => t.completedDay == today).toList(),
        UiTone.violet,
      ),
      (
        s.completedEarlier,
        app.tasks.where((t) => t.done && t.completedDay != today).toList(),
        UiTone.violet,
      ),
    ];
    return ListView(
      key: const PageStorageKey('taskList'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          s.emptyTasksBody,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        if (app.tasks.isEmpty)
          EmptyState(
            icon: Icons.checklist_rounded,
            title: s.emptyTasks,
            body: s.emptyTasksBody,
            action: s.newTask,
            onAction: () => openEditor(context, app, 'task'),
            tone: UiTone.peach,
          )
        else ...[
          SoftPanel(
            tinted: true,
            tone: UiTone.peach,
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                summary(
                  context,
                  Icons.radio_button_unchecked_rounded,
                  s.notCompleted,
                  app.tasks.where((t) => !t.done).length,
                  UiTone.peach,
                ),
                summary(
                  context,
                  Icons.check_circle_outline_rounded,
                  s.finished,
                  app.tasks.where((t) => t.done).length,
                  UiTone.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        for (final group in groups)
          if (group.$2.isNotEmpty) ...[
            SectionTitle(group.$1, count: group.$2.length, tone: group.$3),
            for (final task in group.$2)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftPanel(
                  padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                  tinted: task.done,
                  tone: UiTone.violet,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: IconButton(
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
                          style: IconButton.styleFrom(
                            foregroundColor: group.$3.ink(context),
                          ),
                          icon: Icon(
                            task.done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 25,
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: app.busy
                              ? null
                              : () => openEditor(
                                  context,
                                  app,
                                  'task',
                                  task: task,
                                ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                                        color: task.done
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant
                                            : null,
                                      ),
                                ),
                                const SizedBox(height: 9),
                                AppBadge(
                                  task.dueDay == null
                                      ? s.noDate
                                      : MaterialLocalizations.of(
                                          context,
                                        ).formatMediumDate(task.dueDay!.date),
                                  tone: group.$3,
                                  icon: task.dueDay == null
                                      ? Icons.inbox_outlined
                                      : Icons.schedule_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: s.more,
                        icon: const Icon(Icons.more_horiz_rounded),
                        onPressed: app.busy
                            ? null
                            : () async {
                                final action = await showEntryActions(
                                  context,
                                  task.title,
                                );
                                if (!context.mounted) return;
                                if (action == 'edit') {
                                  await openEditor(
                                    context,
                                    app,
                                    'task',
                                    task: task,
                                  );
                                }
                                if (action == 'delete' &&
                                    context.mounted &&
                                    await confirmDelete(context)) {
                                  await app.run(
                                    () => app.store.remove('tasks', task.id),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget journal(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListView(
      key: const PageStorageKey('journal'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        SoftPanel(
          tinted: true,
          tone: UiTone.violet,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.journalHeading,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.emptyNotesBody,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ToneIcon(
                Icons.edit_note_rounded,
                tone: UiTone.violet,
                size: 52,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (app.notes.isEmpty)
          EmptyState(
            icon: Icons.auto_stories_outlined,
            title: s.emptyNotes,
            body: s.journalEmptyHint,
            action: s.newNote,
            onAction: () => openEditor(context, app, 'note'),
            tone: UiTone.violet,
          ),
        for (final note in app.notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SoftPanel(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppBadge(
                            MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(note.day.date),
                            tone: UiTone.violet,
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: s.more,
                        icon: const Icon(Icons.more_horiz_rounded),
                        onPressed: app.busy
                            ? null
                            : () async {
                                final action = await showEntryActions(
                                  context,
                                  s.note,
                                );
                                if (!context.mounted) return;
                                if (action == 'edit') {
                                  await openEditor(
                                    context,
                                    app,
                                    'note',
                                    note: note,
                                  );
                                }
                                if (action == 'delete' &&
                                    context.mounted &&
                                    await confirmDelete(context)) {
                                  await app.run(
                                    () => app.store.remove('notes', note.id),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => openEditor(context, app, 'note', note: note),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 8,
                        top: 4,
                        bottom: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: UiTone.violet
                                .ink(context)
                                .withValues(alpha: .25),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        note.body,
                        maxLines: 8,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
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
      key: const PageStorageKey('preferences'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        SoftPanel(
          tinted: true,
          tone: UiTone.violet,
          child: Row(
            children: [
              const ToneIcon(Icons.spa_outlined, tone: UiTone.peach, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.freeTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.freeBody,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(s.yourSpace, tone: UiTone.violet),
        SoftPanel(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              SettingRow(
                icon: Icons.grid_view_rounded,
                title: s.manageHabits,
                subtitle:
                    '${app.habits.where((h) => !h.archived).length} ${s.habitCount}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => HabitLibrary(app: app),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 66, right: 14),
                child: Divider(),
              ),
              SettingRow(
                icon: Icons.bar_chart_rounded,
                title: s.review,
                tone: UiTone.violet,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => ReviewPage(app: app)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionTitle(s.preferencesTitle, tone: UiTone.peach),
        SoftPanel(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              SettingRow(
                icon: Icons.palette_outlined,
                title: s.appearance,
                tone: UiTone.peach,
                subtitle: switch (app.preferences['theme']) {
                  'light' => s.light,
                  'dark' => s.dark,
                  _ => s.system,
                },
                onTap: () => preferencePicker(context, 'theme', {
                  'system': s.system,
                  'light': s.light,
                  'dark': s.dark,
                }),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 66, right: 14),
                child: Divider(),
              ),
              SettingRow(
                icon: Icons.translate_rounded,
                title: s.language,
                subtitle: switch (app.preferences['locale']) {
                  'zh' => s.chinese,
                  'en' => s.english,
                  _ => s.system,
                },
                onTap: () => preferencePicker(context, 'locale', {
                  'system': s.system,
                  'zh': s.chinese,
                  'en': s.english,
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SoftPanel(
          tinted: true,
          tone: UiTone.blue,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 20,
                color: UiTone.blue.ink(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.localData,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      s.localDataBody,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SettingRow(
          icon: Icons.code_rounded,
          title: s.licenses,
          tone: UiTone.violet,
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
    final s = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => SheetFrame(
        title: key == 'theme' ? s.appearance : s.language,
        icon: key == 'theme' ? Icons.palette_outlined : Icons.translate_rounded,
        tone: UiTone.violet,
        body: Column(
          children: choices.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SoftPanel(
                    tinted: (app.preferences[key] ?? 'system') == e.key,
                    tone: UiTone.violet,
                    padding: EdgeInsets.zero,
                    child: SettingRow(
                      icon: key == 'theme'
                          ? switch (e.key) {
                              'light' => Icons.light_mode_outlined,
                              'dark' => Icons.nights_stay_outlined,
                              _ => Icons.brightness_auto_outlined,
                            }
                          : Icons.translate_rounded,
                      title: e.value,
                      tone: UiTone.violet,
                      onTap: () => Navigator.pop(ctx, e.key),
                      trailing: Icon(
                        (app.preferences[key] ?? 'system') == e.key
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: UiTone.violet.ink(ctx),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        footer: AppAction(
          label: s.cancel,
          onTap: () => Navigator.pop(ctx),
          tone: UiTone.violet,
        ),
      ),
    );
    if (selected != null) {
      await app.run(() => app.store.preference(key, selected));
    }
  }

  Widget summary(
    BuildContext context,
    IconData icon,
    String label,
    int value,
    UiTone tone,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ToneIcon(icon, tone: tone, size: 40),
      const SizedBox(width: 10),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}
