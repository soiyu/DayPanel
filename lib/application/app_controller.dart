import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_store.dart';
import '../domain/models.dart';
import '../domain/reminder.dart';
import '../data/reminder_platform.dart';

class AppController extends ChangeNotifier {
  AppController(this.store, {DateTime Function()? clock, this.reminderPlatform})
    : clock = clock ?? DateTime.now {
    selectedDay = today;
  }
  final AppStore store;
  final ReminderPlatform? reminderPlatform;
  ReminderStatus reminderStatus = const ReminderStatus(available: false);
  List<HabitReminder> reminders = [];
  bool reminderSyncFailed = false;
  HabitReminder reminderFor(String id) =>
      reminders.where((r) => r.habitId == id).firstOrNull ??
      HabitReminder(habitId: id, enabled: false, minutes: [9 * 60]);
  Future<void> syncReminders() async {
    if (reminderPlatform == null) return;
    try {
      reminderStatus = await reminderPlatform!.sync();
      reminderSyncFailed = false;
    } catch (_) {
      reminderSyncFailed = true;
      reminderStatus = const ReminderStatus(available: false);
    }
    notifyListeners();
  }

  final DateTime Function() clock;
  Day get today => Day(clock());
  late Day selectedDay;
  List<Habit> habits = [];
  List<HabitEntry> entries = [];
  List<SmallTask> tasks = [];
  List<TaskEntry> taskEntries = [];
  List<Note> notes = [];
  Map<String, String> preferences = {};
  List<HabitPlan> plans = [];
  List<HabitGroup> groups = [];
  int generation = 0;
  String? groupFilter;
  HabitContext? contextFilter;
  bool ready = false;
  bool busy = false;
  String? error;

  Future<void> load() async {
    final h = await store.habits();
    final e = await store.entries();
    final t = await store.tasks();
    final te = await store.taskEntries();
    final n = await store.notes();
    final p = await store.settings();
    final versions = await store.plans();
    final g = await store.groups();
    final epoch = await store.generation();
    final remindersSaved = await store.reminders();
    habits = h;
    entries = e;
    tasks = t;
    taskEntries = te;
    notes = n;
    preferences = p;
    plans = versions;
    groups = g;
    generation = epoch;
    reminders = remindersSaved;
    if (groupFilter != null && !g.any((g) => g.id == groupFilter)) {
      groupFilter = null;
    }
    ready = true;
    notifyListeners();
  }

  Future<bool> run(
    Future<void> Function() operation, {
    int? expectedGeneration,
  }) async {
    if (busy) return false;
    if (expectedGeneration != null && expectedGeneration != generation) {
      error = 'storage';
      notifyListeners();
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final storedGeneration = await store.generation();
      if (storedGeneration != generation) {
        await load();
        throw StateError('Data generation changed; refresh before retrying');
      }
      await operation();
      await load();
      await syncReminders();
      return true;
    } catch (_) {
      error = 'storage'; // UI localizes; no personal content in logs.
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void select(Day day) {
    selectedDay = day;
    notifyListeners();
  }

  bool taskDoneOn(SmallTask task, Day day) => task.resident
      ? taskEntries.any((e) => e.taskId == task.id && e.day == day)
      : task.completedDay == day;
  List<SmallTask> get oneTimeTasks => tasks.where((t) => !t.resident).toList();
  List<SmallTask> get residentTasks =>
      tasks.where((t) => t.resident && !t.archived).toList();
  int tasksCompletedOn(Day day) =>
      oneTimeTasks.where((t) => t.completedDay == day).length +
      taskEntries.where((e) => e.day == day).length;
  Future<bool> recordResidentToday(
    SmallTask task,
    Day renderedDay,
    bool done,
    int epoch,
  ) => run(() async {
    if (renderedDay != today) throw StateError('Day changed');
    await store.setResidentRecord(task.id, renderedDay, done, today: today);
  }, expectedGeneration: epoch);

  void acknowledgeError() {
    error = null;
    notifyListeners();
  }

  int? value(Habit h, Day day) {
    for (final e in entries) {
      if (e.habitId == h.id && e.day == day) return e.value;
    }
    return null;
  }

  HabitPlan planAt(Habit h, Day day) => plans.lastWhere(
    (p) => p.habitId == h.id && p.effectiveDay.compareTo(day) <= 0,
    orElse: () => HabitPlan.fromHabit(h, h.startDay),
  );
  Habit forDay(Habit h, Day day) => h.withPlan(planAt(h, day));
  HabitPlan? pending(Habit h) => plans
      .where((p) => p.habitId == h.id && p.effectiveDay.compareTo(today) > 0)
      .firstOrNull;
  bool scheduled(Habit h, Day day) =>
      !h.archived &&
      day.compareTo(h.startDay) >= 0 &&
      planAt(h, day).scheduled(day);
  bool achieved(Habit h, Day day) =>
      (value(h, day) ?? -1) >= planAt(h, day).target;
  int weekCount(Habit h, Day day) {
    final plan = planAt(h, day);
    final start = day.monday.compareTo(plan.effectiveDay) < 0
        ? plan.effectiveDay
        : day.monday;
    final end = day.compareTo(today) > 0 ? today : day;
    return entries
        .where(
          (e) =>
              e.habitId == h.id &&
              e.day.compareTo(start) >= 0 &&
              e.day.compareTo(end) <= 0 &&
              e.value >= plan.target,
        )
        .length;
  }

  bool matchesFilter(Habit h) =>
      (contextFilter == null || h.context == contextFilter) &&
      (groupFilter == null || h.groupId == groupFilter);
  void filter({HabitContext? context, String? group}) {
    contextFilter = context;
    groupFilter = group;
    notifyListeners();
  }

  List<Habit> get dailyPlanned => habits
      .where(
        (h) =>
            scheduled(h, selectedDay) &&
            planAt(h, selectedDay).schedule != ScheduleKind.weekly &&
            matchesFilter(h),
      )
      .toList();
  List<Habit> get weeklyPlanned => habits
      .where(
        (h) =>
            scheduled(h, selectedDay) &&
            planAt(h, selectedDay).schedule == ScheduleKind.weekly &&
            matchesFilter(h),
      )
      .toList();
  List<Habit> get planned => dailyPlanned;
  int get completed => planned.where((h) => achieved(h, selectedDay)).length;
  List<Habit> get allDailyPlanned => habits
      .where(
        (h) =>
            scheduled(h, selectedDay) &&
            planAt(h, selectedDay).schedule != ScheduleKind.weekly,
      )
      .toList();
  int get allDailyCompleted =>
      allDailyPlanned.where((h) => achieved(h, selectedDay)).length;
}
