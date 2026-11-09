import 'dart:async';
import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'editors.dart';
import 'theme.dart';
import 'refined_components.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key, required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final today = app.today;
    final singles = app.oneTimeTasks;
    final groups = <(String, List<SmallTask>, UiTone)>[
      (
        s.todayLabel,
        singles.where((t) => !t.done && t.dueDay == today).toList(),
        UiTone.blue,
      ),
      (
        s.overdue,
        singles
            .where(
              (t) =>
                  !t.done && t.dueDay != null && t.dueDay!.compareTo(today) < 0,
            )
            .toList(),
        UiTone.peach,
      ),
      (
        s.inbox,
        singles.where((t) => !t.done && t.dueDay == null).toList(),
        UiTone.violet,
      ),
      (
        s.upcoming,
        singles
            .where(
              (t) =>
                  !t.done && t.dueDay != null && t.dueDay!.compareTo(today) > 0,
            )
            .toList(),
        UiTone.blue,
      ),
      (
        s.completedToday,
        singles.where((t) => t.completedDay == today).toList(),
        UiTone.violet,
      ),
    ];
    List<Widget> section(String name, List<SmallTask> tasks, UiTone tone) =>
        tasks.isEmpty
        ? []
        : [
            SectionTitle(name, count: tasks.length, tone: tone),
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskTile(app: app, task: task, tone: tone),
              ),
          ];
    return ListView(
      key: const PageStorageKey('taskList'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${s.taskSummaryPending} ${singles.where((t) => !t.done).length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              key: const Key('task-history'),
              tooltip: s.taskHistory,
              icon: const Icon(Icons.history_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TaskHistoryPage(app: app),
                ),
              ),
            ),
            if (app.tasks.any((t) => t.resident && t.archived))
              IconButton(
                tooltip: s.archived,
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TaskArchivePage(app: app),
                  ),
                ),
              ),
          ],
        ),
        if (app.tasks.isEmpty)
          EmptyState(
            icon: Icons.checklist_rounded,
            title: s.emptyTasks,
            body: s.emptyTasksBody,
            action: s.newTask,
            onAction: () => openEditor(context, app, 'task'),
            tone: UiTone.peach,
          ),
        for (final group in groups.take(2))
          ...section(group.$1, group.$2, group.$3),
        ...section(s.residentTasks, app.residentTasks, UiTone.violet),
        for (final group in groups.skip(2).take(2))
          ...section(group.$1, group.$2, group.$3),
        ...section(groups.last.$1, groups.last.$2, groups.last.$3),
        if (singles.any((t) => t.done && t.completedDay != today))
          SettingRow(
            icon: Icons.history_rounded,
            title: s.completedEarlier,
            subtitle:
                '${singles.where((t) => t.done && t.completedDay != today).length}',
            tone: UiTone.violet,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TaskHistoryPage(app: app),
              ),
            ),
          ),
      ],
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.app,
    required this.task,
    this.tone = UiTone.blue,
  });
  final AppController app;
  final SmallTask task;
  final UiTone tone;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final day = app.today;
    final epoch = app.generation;
    final done = task.resident ? app.taskDoneOn(task, day) : task.done;
    void open() {
      if (task.resident) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ResidentTaskPage(app: app, id: task.id),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => OneTimeTaskPage(app: app, id: task.id),
          ),
        );
      }
    }

    return SoftPanel(
      tinted: done,
      tone: tone,
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: IconButton(
              key: Key('task-action-${task.id}'),
              tooltip: done ? s.reopen : s.done,
              onPressed: app.busy || task.archived
                  ? null
                  : () {
                      if (task.resident) {
                        app.recordResidentToday(task, day, !done, epoch);
                      } else {
                        app.run(
                          () =>
                              app.store.completeTask(task.id, !done, app.today),
                          expectedGeneration: epoch,
                        );
                      }
                    },
              style: IconButton.styleFrom(foregroundColor: tone.ink(context)),
              icon: Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 25,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: app.busy ? null : open,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: done && !task.resident
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppBadge(
                      task.resident
                          ? (done ? s.residentToday : s.residentUnrecorded)
                          : task.dueDay == null
                          ? s.noDate
                          : MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(task.dueDay!.date),
                      tone: tone,
                      icon: task.resident
                          ? Icons.bookmark_border_rounded
                          : task.dueDay == null
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
                    final action = await showEntryActions(context, task.title);
                    if (!context.mounted) return;
                    if (action == 'edit') {
                      await openEditor(context, app, 'task', task: task);
                    }
                    if (action == 'delete' &&
                        context.mounted &&
                        await confirmTaskDelete(context, task)) {
                      await app.run(
                        () => app.store.remove('tasks', task.id),
                        expectedGeneration: epoch,
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmTaskDelete(BuildContext context, SmallTask task) async {
  if (!task.resident) return confirmDelete(context);
  final s = AppLocalizations.of(context);
  return await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (ctx) => SheetFrame(
          title: s.delete,
          icon: Icons.delete_outline_rounded,
          tone: UiTone.peach,
          body: Text(s.residentDeleteWarning),
          footer: Row(
            children: [
              Expanded(
                child: AppAction(
                  label: s.cancel,
                  onTap: () => Navigator.pop(ctx, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppAction(
                  label: s.delete,
                  danger: true,
                  onTap: () => Navigator.pop(ctx, true),
                ),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Widget taskContextUnavailable(BuildContext context, {required bool stale}) {
  final s = AppLocalizations.of(context);
  return AppCanvas(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(s.task)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            EmptyState(
              icon: Icons.info_outline_rounded,
              title: stale ? s.contextChanged : s.pmTaskUnavailable,
              body: s.reopenContext,
              action: s.back,
              actionIcon: Icons.arrow_back_rounded,
              onAction: () => Navigator.maybePop(context),
              tone: UiTone.peach,
            ),
          ],
        ),
      ),
    ),
  );
}

class ResidentTaskPage extends StatefulWidget {
  const ResidentTaskPage({
    super.key,
    required this.app,
    required this.id,
    this.initialDay,
  });
  final AppController app;
  final String id;
  final Day? initialDay;
  @override
  State<ResidentTaskPage> createState() => _ResidentTaskPageState();
}

class _ResidentTaskPageState extends State<ResidentTaskPage>
    with WidgetsBindingObserver {
  Day? selected;
  Timer? timer;
  late final int epoch;
  @override
  void initState() {
    super.initState();
    selected = widget.initialDay;
    epoch = widget.app.generation;
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final app = widget.app;
      final task = app.tasks.where((t) => t.id == widget.id).firstOrNull;
      if (epoch != app.generation || task == null || !task.resident) {
        return taskContextUnavailable(context, stale: epoch != app.generation);
      }
      final s = AppLocalizations.of(context);
      final day = selected ?? app.today;
      final valid =
          day.compareTo(task.startDay!) >= 0 && day.compareTo(app.today) <= 0;
      final done = app.taskDoneOn(task, day);
      final entries = app.taskEntries.where((e) => e.taskId == task.id).toList()
        ..sort((a, b) => b.day.compareTo(a.day));
      Future<void> selectDate() async {
        if (app.today.compareTo(task.startDay!) < 0) return;
        final d = await showDatePicker(
          context: context,
          initialDate: (valid ? day : app.today).date,
          firstDate: task.startDay!.date,
          lastDate: app.today.date,
        );
        if (d != null && mounted) setState(() => selected = Day(d));
      }

      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(task.title),
            actions: [
              IconButton(
                tooltip: s.edit,
                onPressed: app.busy
                    ? null
                    : () => openEditor(
                        context,
                        app,
                        'task',
                        task: task,
                        expectedGeneration: epoch,
                      ),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (app.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    s.storageError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SoftPanel(
                tinted: true,
                tone: UiTone.violet,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppBadge(s.residentTask, tone: UiTone.violet),
                        if (task.archived)
                          AppBadge(s.archived, tone: UiTone.peach),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatFullDate(day.date),
                      key: const Key('resident-record-day'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day == app.today
                          ? (done ? s.residentToday : s.residentUnrecorded)
                          : (done ? s.finished : s.notRecorded),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    AppAction(
                      key: const Key('resident-record'),
                      label: done ? s.clearThisDay : s.recordThisDay,
                      icon: done ? Icons.undo_rounded : Icons.check_rounded,
                      primary: !done,
                      tone: UiTone.violet,
                      onTap: app.busy || task.archived || !valid
                          ? null
                          : () => selected == null
                                ? app.recordResidentToday(
                                    task,
                                    day,
                                    !done,
                                    epoch,
                                  )
                                : app.run(
                                    () => app.store.setResidentRecord(
                                      task.id,
                                      day,
                                      !done,
                                      today: app.today,
                                    ),
                                    expectedGeneration: epoch,
                                  ),
                    ),
                    if (selected != null)
                      TextButton(
                        onPressed: () => setState(() => selected = null),
                        child: Text(s.todayLabel),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DetailDisclosure(
                key: const Key('resident-history'),
                title: s.editTaskHistory,
                icon: Icons.history_rounded,
                initiallyExpanded: widget.initialDay != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingRow(
                      key: const Key('resident-history-date'),
                      icon: Icons.calendar_month_outlined,
                      title: s.chooseDate,
                      subtitle: MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(day.date),
                      tone: UiTone.peach,
                      onTap: selectDate,
                    ),
                    Text(
                      s.residentHistoryHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SectionTitle(
                      s.taskHistory,
                      count: entries.length,
                      tone: UiTone.violet,
                    ),
                    if (entries.isEmpty)
                      Text(
                        s.noTaskHistory,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    for (final entry in entries)
                      SettingRow(
                        icon: Icons.check_circle_outline_rounded,
                        title: MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(entry.day.date),
                        subtitle: s.finished,
                        tone: UiTone.violet,
                        onTap: () => setState(() => selected = entry.day),
                      ),
                  ],
                ),
              ),
              DetailDisclosure(
                key: const Key('task-management'),
                title: s.more,
                icon: Icons.tune_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${s.residentDetailHint}\n${s.residentStart} ${MaterialLocalizations.of(context).formatMediumDate(task.startDay!.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.taskArchiveHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    AppAction(
                      label: task.archived ? s.unarchive : s.archive,
                      icon: Icons.archive_outlined,
                      tone: UiTone.violet,
                      onTap: app.busy
                          ? null
                          : () => app.run(
                              () => app.store.archiveTask(
                                task.id,
                                !task.archived,
                              ),
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
                              if (!await confirmTaskDelete(context, task)) {
                                return;
                              }
                              final ok = await app.run(
                                () => app.store.remove('tasks', task.id),
                                expectedGeneration: epoch,
                              );
                              if (ok && context.mounted) Navigator.pop(context);
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({super.key, required this.app});
  final AppController app;
  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  late Day day;
  @override
  void initState() {
    super.initState();
    day = widget.app.today;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final app = widget.app;
      final s = AppLocalizations.of(context);
      final tasks = app.tasks.where((t) => app.taskDoneOn(t, day)).toList();
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.taskHistory)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SoftPanel(
                tinted: true,
                tone: UiTone.violet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.historyShowsBoth),
                    const SizedBox(height: 10),
                    Text(
                      s.taskHistoryEditHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).previousPageTooltip,
                    onPressed: day.date.year <= 1900
                        ? null
                        : () => setState(() => day = day.plus(-1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: day.compareTo(app.today) > 0
                              ? app.today.date
                              : day.date,
                          firstDate: DateTime(1900),
                          lastDate: app.today.date,
                        );
                        if (d != null && mounted) setState(() => day = Day(d));
                      },
                      child: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(day.date),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                    onPressed: day.compareTo(app.today) >= 0
                        ? null
                        : () => setState(() => day = day.plus(1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              SectionTitle(
                s.taskHistoryCount,
                count: tasks.length,
                tone: UiTone.violet,
              ),
              if (tasks.isEmpty)
                EmptyState(
                  icon: Icons.history_rounded,
                  title: s.noTaskHistory,
                  body: s.residentDetailHint,
                  tone: UiTone.violet,
                ),
              for (final task in tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftPanel(
                    padding: const EdgeInsets.all(3),
                    child: SettingRow(
                      icon: task.resident
                          ? Icons.bookmark_border_rounded
                          : Icons.check_circle_outline_rounded,
                      title: task.title,
                      subtitle:
                          '${task.resident ? s.residentTask : s.oneTimeTask}${task.archived ? ' · ${s.archived}' : ''}',
                      tone: task.resident ? UiTone.violet : UiTone.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => task.resident
                              ? ResidentTaskPage(
                                  app: app,
                                  id: task.id,
                                  initialDay: day,
                                )
                              : OneTimeTaskPage(app: app, id: task.id),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class OneTimeTaskPage extends StatefulWidget {
  const OneTimeTaskPage({super.key, required this.app, required this.id});
  final AppController app;
  final String id;
  @override
  State<OneTimeTaskPage> createState() => _OneTimeTaskPageState();
}

class _OneTimeTaskPageState extends State<OneTimeTaskPage> {
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
      final task = app.tasks.where((t) => t.id == widget.id).firstOrNull;
      if (epoch != app.generation || task == null || task.resident) {
        return taskContextUnavailable(context, stale: epoch != app.generation);
      }
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(task.title),
            actions: [
              IconButton(
                tooltip: s.edit,
                onPressed: app.busy
                    ? null
                    : () => openEditor(
                        context,
                        app,
                        'task',
                        task: task,
                        expectedGeneration: epoch,
                      ),
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
              SoftPanel(
                tinted: true,
                tone: UiTone.peach,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppBadge(s.oneTimeTask, tone: UiTone.peach),
                    const SizedBox(height: 12),
                    Text(
                      task.dueDay == null
                          ? s.noDate
                          : '${s.dueDate} · ${MaterialLocalizations.of(context).formatMediumDate(task.dueDay!.date)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.completedDay == null
                          ? s.notRecorded
                          : '${s.finished} ${MaterialLocalizations.of(context).formatMediumDate(task.completedDay!.date)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    AppAction(
                      key: const Key('one-time-record'),
                      label: task.done ? s.reopen : s.done,
                      primary: !task.done,
                      icon: task.done
                          ? Icons.undo_rounded
                          : Icons.check_rounded,
                      onTap: app.busy
                          ? null
                          : () => app.run(
                              () => app.store.completeTask(
                                task.id,
                                !task.done,
                                app.today,
                              ),
                              expectedGeneration: epoch,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DetailDisclosure(
                key: const Key('task-management'),
                title: s.more,
                icon: Icons.tune_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.oneTimeHelp,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    AppAction(
                      label: s.delete,
                      icon: Icons.delete_outline,
                      danger: true,
                      onTap: app.busy
                          ? null
                          : () async {
                              if (!await confirmTaskDelete(context, task)) {
                                return;
                              }
                              final ok = await app.run(
                                () => app.store.remove('tasks', task.id),
                                expectedGeneration: epoch,
                              );
                              if (ok && context.mounted) Navigator.pop(context);
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class TaskArchivePage extends StatelessWidget {
  const TaskArchivePage({super.key, required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final archived = app.tasks
          .where((t) => t.resident && t.archived)
          .toList();
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.taskArchive)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(s.taskArchiveHint),
              const SizedBox(height: 18),
              if (archived.isEmpty)
                EmptyState(
                  icon: Icons.archive_outlined,
                  title: s.noArchivedTasks,
                  body: s.taskArchiveHint,
                ),
              for (final task in archived)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftPanel(
                    padding: const EdgeInsets.all(4),
                    child: SettingRow(
                      icon: Icons.bookmark_border_rounded,
                      title: task.title,
                      tone: UiTone.violet,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ResidentTaskPage(app: app, id: task.id),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
