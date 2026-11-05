import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_store.dart';
import '../domain/models.dart';

class AppController extends ChangeNotifier {
  AppController(this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now {
    selectedDay = today;
  }
  final AppStore store;
  final DateTime Function() clock;
  Day get today => Day(clock());
  late Day selectedDay;
  List<Habit> habits = [];
  List<HabitEntry> entries = [];
  List<SmallTask> tasks = [];
  List<Note> notes = [];
  Map<String, String> preferences = {};
  bool ready = false;
  bool busy = false;
  String? error;

  Future<void> load() async {
    final h = await store.habits();
    final e = await store.entries();
    final t = await store.tasks();
    final n = await store.notes();
    final p = await store.settings();
    habits = h;
    entries = e;
    tasks = t;
    notes = n;
    preferences = p;
    ready = true;
    notifyListeners();
  }

  Future<bool> run(Future<void> Function() operation) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await operation();
      await load();
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

  bool achieved(Habit h, Day day) => (value(h, day) ?? -1) >= h.target;
  List<Habit> get planned =>
      habits.where((h) => h.scheduled(selectedDay)).toList();
  int get completed => planned.where((h) => achieved(h, selectedDay)).length;
}
