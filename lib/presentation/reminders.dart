import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../domain/reminder.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'habit_icon.dart';
import 'refined_components.dart';

String formatReminderTimes(BuildContext context, List<int> minutes) =>
    (minutes.toList()..sort())
        .map((m) => TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context))
        .join(' · ');

Future<void> openReminderEditor(
  BuildContext context,
  AppController app,
  Habit habit,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => ReminderEditor(app: app, habit: habit),
);

class ReminderEditor extends StatefulWidget {
  const ReminderEditor({super.key, required this.app, required this.habit});
  final AppController app;
  final Habit habit;
  @override
  State<ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<ReminderEditor> {
  late bool enabled;
  late List<int> times;
  late int epoch;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final r = widget.app.reminderFor(widget.habit.id);
    enabled = r.enabled;
    times = List.of(r.minutes);
    epoch = widget.app.generation;
  }

  Future<void> pick([int? old]) async {
    final s = AppLocalizations.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: old == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: old ~/ 60, minute: old % 60),
    );
    if (picked == null || !mounted) return;
    final minute = picked.hour * 60 + picked.minute;
    if (times.contains(minute) && minute != old) {
      setState(() => error = s.reminderLimit);
      return;
    }
    setState(() {
      if (old != null) {
        times.remove(old);
      } else if (times.length >= 5) {
        error = s.reminderLimit;
        return;
      }
      times.add(minute);
      times = times.toSet().toList()..sort();
      error = null;
    });
  }

  Future<void> save() async {
    if (saving) return;
    final s = AppLocalizations.of(context);
    if (times.isEmpty) {
      setState(() => error = s.reminderLimit);
      return;
    }
    setState(() => saving = true);
    if (enabled && widget.app.reminderPlatform != null) {
      try {
        widget.app.reminderStatus = await widget.app.reminderPlatform!
            .requestPermission();
      } catch (_) {
        /* Save config even when system permission cannot be requested. */
      }
    }
    final ok = await widget.app.run(
      () => widget.app.store.saveReminder(
        HabitReminder(
          habitId: widget.habit.id,
          enabled: enabled,
          minutes: times,
        ),
      ),
      expectedGeneration: epoch,
    );
    if (!mounted) return;
    if (ok) {
      final message = widget.app.reminderSyncFailed
          ? s.reminderSyncFailed
          : enabled && !widget.app.reminderStatus.notifications
          ? s.reminderSavedBlocked
          : s.saved;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        error = s.reminderSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SheetFrame(
      title: s.habitReminder,
      subtitle: widget.habit.title,
      icon: Icons.notifications_none_rounded,
      tone: UiTone.peach,
      busy: saving,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftPanel(
            tinted: true,
            tone: UiTone.peach,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Material(
              color: Colors.transparent,
              child: SwitchListTile(
                key: const Key('enable-reminder'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  s.reminderOn,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                value: enabled,
                onChanged: saving ? null : (v) => setState(() => enabled = v),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            s.reminderPermissionHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            s.reminderSharedGoal,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SectionTitle(s.reminderTimes, tone: UiTone.peach),
          for (final minute in times)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftPanel(
                padding: const EdgeInsets.all(4),
                child: SettingRow(
                  icon: Icons.schedule_rounded,
                  title: TimeOfDay(
                    hour: minute ~/ 60,
                    minute: minute % 60,
                  ).format(context),
                  tone: UiTone.peach,
                  onTap: saving ? null : () => pick(minute),
                  trailing: IconButton(
                    tooltip: s.removeTime,
                    onPressed: saving || times.length == 1
                        ? null
                        : () => setState(() => times.remove(minute)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ),
              ),
            ),
          AppAction(
            label: s.addReminderTime,
            icon: Icons.add,
            tone: UiTone.violet,
            onTap: saving || times.length >= 5 ? null : pick,
          ),
          const SizedBox(height: 18),
          Text(
            s.reminderScheduleHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            s.reminderLocalTime,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (widget.habit.archived) ...[
            const SizedBox(height: 12),
            AppBadge(s.reminderArchived, tone: UiTone.peach),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppAction(
              label: s.cancel,
              onTap: saving ? null : () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppAction(
              key: const Key('save-reminder'),
              label: s.save,
              primary: true,
              busy: saving,
              onTap: saving ? null : save,
            ),
          ),
        ],
      ),
    );
  }
}

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.app});
  final AppController app;
  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage>
    with WidgetsBindingObserver {
  bool working = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.app.syncReminders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.app.syncReminders();
  }

  Future<void> systemAction(Future<void> Function() action) async {
    if (working) return;
    setState(() {
      working = true;
      error = null;
    });
    try {
      await action();
      await widget.app.syncReminders();
    } catch (_) {
      if (mounted) error = AppLocalizations.of(context).reminderSettingsFailed;
    }
    if (mounted) setState(() => working = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final app = widget.app;
      final s = AppLocalizations.of(context);
      final status = app.reminderStatus;
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.remindersTitle)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status.notifications
                          ? s.notificationAllowed
                          : s.notificationBlocked,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: s.notificationSettings,
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: working
                        ? null
                        : () => systemAction(() async {
                            await app.reminderPlatform?.openSettings();
                          }),
                  ),
                ],
              ),
              if (!status.notifications)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: working
                        ? null
                        : () => systemAction(() async {
                            await app.reminderPlatform?.requestPermission();
                          }),
                    child: Text(s.enableNotifications),
                  ),
                ),
              if (app.reminderSyncFailed || error != null) ...[
                const SizedBox(height: 16),
                Text(error ?? s.reminderSyncFailed),
                TextButton(
                  onPressed: working
                      ? null
                      : () => systemAction(app.syncReminders),
                  child: Text(s.retry),
                ),
              ],
              const SizedBox(height: 6),
              SectionTitle(
                s.manageHabits,
                count: app.habits.length,
                tone: UiTone.peach,
              ),
              if (app.habits.isEmpty)
                EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: s.noReminders,
                  body: s.noRemindersBody,
                  tone: UiTone.peach,
                ),
              for (final h in app.habits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftPanel(
                    padding: const EdgeInsets.all(4),
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
                      subtitle: h.archived
                          ? s.reminderArchived
                          : app.reminderFor(h.id).enabled
                          ? formatReminderTimes(
                              context,
                              app.reminderFor(h.id).minutes,
                            )
                          : s.reminderOff,
                      onTap: app.busy
                          ? null
                          : () => openReminderEditor(context, app, h),
                    ),
                  ),
                ),
              DetailDisclosure(
                title: s.notificationSettings,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle(s.notificationSettings),
                    SoftPanel(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppBadge(
                            status.notifications
                                ? s.notificationAllowed
                                : s.notificationBlocked,
                            tone: status.notifications
                                ? UiTone.blue
                                : UiTone.peach,
                          ),
                          const SizedBox(height: 14),
                          if (!status.notifications)
                            AppAction(
                              label: s.enableNotifications,
                              primary: true,
                              onTap: working
                                  ? null
                                  : () => systemAction(() async {
                                      await app.reminderPlatform
                                          ?.requestPermission();
                                    }),
                            ),
                          const SizedBox(height: 8),
                          AppAction(
                            label: s.notificationSettings,
                            icon: Icons.settings_outlined,
                            onTap: working
                                ? null
                                : () => systemAction(() async {
                                    await app.reminderPlatform?.openSettings();
                                  }),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            s.reminderChannelHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SoftPanel(
                      tinted: true,
                      tone: UiTone.violet,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.exactReminder,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            status.exact
                                ? s.exactAvailable
                                : s.exactUnavailable,
                          ),
                          if (!status.exact) ...[
                            const SizedBox(height: 12),
                            AppAction(
                              label: s.requestExact,
                              icon: Icons.alarm_rounded,
                              tone: UiTone.violet,
                              onTap: working
                                  ? null
                                  : () => systemAction(() async {
                                      await app.reminderPlatform?.openSettings(
                                        exact: true,
                                      );
                                    }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              DetailDisclosure(
                title: s.uiReminderRules,
                child: Text('${s.remindersIntro}\n\n${s.snoozeHint}'),
              ),
              const SizedBox(height: 14),
              Text(
                s.reminderSystemHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Text(
                s.reminderBackups,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    },
  );
}
