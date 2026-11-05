import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';

String contextName(AppLocalizations s, HabitContext c) => switch (c) {
  HabitContext.anytime => s.anytime,
  HabitContext.morning => s.morning,
  HabitContext.daytime => s.daytime,
  HabitContext.evening => s.evening,
};
IconData contextIcon(HabitContext c) => switch (c) {
  HabitContext.anytime => Icons.all_inclusive_rounded,
  HabitContext.morning => Icons.wb_sunny_outlined,
  HabitContext.daytime => Icons.light_mode_outlined,
  HabitContext.evening => Icons.nights_stay_outlined,
};
String scheduleText(AppLocalizations s, HabitPlan p) => switch (p.schedule) {
  ScheduleKind.weekdays =>
    p.weekdays == 127
        ? s.everyDay
        : [
            for (var i = 0; i < 7; i++)
              if (p.weekdays & (1 << i) != 0)
                [
                  s.weekMonFull,
                  s.weekTueFull,
                  s.weekWedFull,
                  s.weekThuFull,
                  s.weekFriFull,
                  s.weekSatFull,
                  s.weekSunFull,
                ][i],
          ].join(' · '),
  ScheduleKind.interval => '${s.intervalLabel}: ${p.intervalDays}',
  ScheduleKind.weekly => '${s.weeklyGoalLabel}: ${p.weeklyGoal}',
};

Future<void> showHabitFilter(BuildContext context, AppController app) async {
  var selectedContext = app.contextFilter;
  var selectedGroup = app.groupFilter;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) {
        final s = AppLocalizations.of(ctx);
        return SheetFrame(
          title: s.filterHabits,
          icon: Icons.tune_rounded,
          tone: UiTone.violet,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(s.contextLabel, tone: UiTone.peach),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in [null, ...HabitContext.values])
                    AppAction(
                      icon: selectedContext == c
                          ? Icons.check_circle_rounded
                          : c == null
                          ? Icons.apps_rounded
                          : contextIcon(c),
                      label: c == null ? s.allHabits : contextName(s, c),
                      tone: UiTone.peach,
                      onTap: () => setModal(() => selectedContext = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SectionTitle(s.groupLabel, tone: UiTone.violet),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in <HabitGroup?>[null, ...app.groups])
                    AppAction(
                      icon: selectedGroup == g?.id
                          ? Icons.check_circle_rounded
                          : Icons.folder_outlined,
                      label: g?.name ?? s.allGroups,
                      tone: UiTone.violet,
                      onTap: () => setModal(() => selectedGroup = g?.id),
                    ),
                ],
              ),
            ],
          ),
          footer: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppAction(
                label: s.resetFilter,
                onTap: () {
                  app.filter();
                  Navigator.pop(ctx);
                },
              ),
              AppAction(
                label: s.applyFilter,
                primary: true,
                onTap: () {
                  app.filter(context: selectedContext, group: selectedGroup);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key, required this.app});
  final AppController app;
  Future<void> edit(BuildContext context, [HabitGroup? group]) async {
    final field = TextEditingController(text: group?.name ?? '');
    final epoch = app.generation;
    var saving = false;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final s = AppLocalizations.of(ctx);
          return SheetFrame(
            title: group == null ? s.newGroup : s.edit,
            icon: Icons.folder_outlined,
            tone: UiTone.violet,
            busy: saving,
            body: TextField(
              key: const Key('group-name'),
              controller: field,
              enabled: !saving,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: s.groupName,
                errorText: error,
              ),
            ),
            footer: AppAction(
              label: s.save,
              primary: true,
              busy: saving,
              onTap: saving
                  ? null
                  : () async {
                      final name = field.text.trim();
                      if (name.isEmpty ||
                          app.groups.any(
                            (g) =>
                                g.id != group?.id &&
                                g.name.toLowerCase() == name.toLowerCase(),
                          )) {
                        setModal(() => error = s.groupNameError);
                        return;
                      }
                      setModal(() => saving = true);
                      final ok = await app.run(
                        () => app.store.saveGroup(
                          HabitGroup(
                            id: group?.id ?? const Uuid().v4(),
                            name: name,
                          ),
                          create: group == null,
                        ),
                        expectedGeneration: epoch,
                      );
                      if (!ctx.mounted) return;
                      if (ok) {
                        Navigator.pop(ctx);
                      } else {
                        setModal(() {
                          saving = false;
                          error = s.storageError;
                        });
                      }
                    },
            ),
          );
        },
      ),
    );
    // The modal transition may still own the text field at completion.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    field.dispose();
  }

  Future<void> remove(BuildContext context, HabitGroup group) async {
    final s = AppLocalizations.of(context);
    final epoch = app.generation;
    final yes = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => SheetFrame(
        title: group.name,
        icon: Icons.folder_delete_outlined,
        tone: UiTone.peach,
        body: Text(s.groupDeleteHint),
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
    );
    if (yes == true) {
      await app.run(
        () => app.store.removeGroup(group.id),
        expectedGeneration: epoch,
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.manageGroups),
            actions: [
              AppIconAction(
                icon: Icons.add,
                label: s.newGroup,
                onTap: app.busy ? null : () => edit(context),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (app.error != null) Text(s.storageError),
              if (app.groups.isEmpty)
                EmptyState(
                  icon: Icons.folder_outlined,
                  title: s.noGroups,
                  body: s.noGroupsBody,
                  action: s.newGroup,
                  onAction: () => edit(context),
                  tone: UiTone.violet,
                ),
              for (final group in app.groups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SoftPanel(
                    padding: const EdgeInsets.all(4),
                    child: SettingRow(
                      icon: Icons.folder_outlined,
                      title: group.name,
                      subtitle:
                          '${app.habits.where((h) => h.groupId == group.id).length} ${s.habitCount}',
                      tone: UiTone.violet,
                      onTap: app.busy ? null : () => edit(context, group),
                      trailing: IconButton(
                        tooltip: s.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: app.busy
                            ? null
                            : () => remove(context, group),
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

class HabitOrderPage extends StatefulWidget {
  const HabitOrderPage({super.key, required this.app});
  final AppController app;
  @override
  State<HabitOrderPage> createState() => _HabitOrderPageState();
}

class _HabitOrderPageState extends State<HabitOrderPage> {
  late List<Habit> items;
  late int epoch;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    items = List.of(widget.app.habits);
    epoch = widget.app.generation;
  }

  void move(int from, int to) {
    if (saving) return;
    setState(() {
      final item = items.removeAt(from);
      items.insert(to, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return PopScope(
      canPop: !saving,
      child: AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.sortHabits),
            automaticallyImplyLeading: !saving,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(error ?? s.sortHint),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  onReorderItem: move,
                  itemBuilder: (ctx, i) => Padding(
                    key: ValueKey(items[i].id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftPanel(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            items[i].title,
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              IconButton(
                                tooltip: s.moveUp,
                                onPressed: saving || i == 0
                                    ? null
                                    : () => move(i, i - 1),
                                icon: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                ),
                              ),
                              IconButton(
                                tooltip: s.moveDown,
                                onPressed: saving || i == items.length - 1
                                    ? null
                                    : () => move(i, i + 1),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                              ),
                              const Spacer(),
                              ReorderableDragStartListener(
                                index: i,
                                enabled: !saving,
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(Icons.drag_handle_rounded),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppAction(
                      label: s.save,
                      primary: true,
                      busy: saving,
                      onTap: saving
                          ? null
                          : () async {
                              setState(() => saving = true);
                              final ok = await widget.app.run(
                                () => widget.app.store.reorderHabits(
                                  items.map((h) => h.id).toList(),
                                ),
                                expectedGeneration: epoch,
                              );
                              if (!context.mounted) return;
                              if (ok) {
                                Navigator.pop(context);
                              } else {
                                setState(() {
                                  saving = false;
                                  error = s.storageError;
                                });
                              }
                            },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
