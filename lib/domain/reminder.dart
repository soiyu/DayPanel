import 'dart:convert';

class HabitReminder {
  HabitReminder({
    required this.habitId,
    required this.enabled,
    required List<int> minutes,
    this.revision = 0,
  }) : minutes = List.unmodifiable(minutes);
  final String habitId;
  final bool enabled;
  final List<int> minutes;
  final int revision;
  bool get valid =>
      minutes.isNotEmpty &&
      minutes.length <= 5 &&
      minutes.toSet().length == minutes.length &&
      minutes.every((m) => m >= 0 && m < 1440) &&
      revision >= 0;
  factory HabitReminder.fromMap(Map<String, Object?> m) => HabitReminder(
    habitId: m['habit_id'] as String,
    enabled: m['enabled'] == 1,
    minutes: (jsonDecode(m['minutes'] as String) as List).cast<int>(),
    revision: m['revision'] as int,
  );
  Map<String, Object?> toMap() => {
    'habit_id': habitId,
    'enabled': enabled ? 1 : 0,
    'minutes': jsonEncode(minutes.toList()..sort()),
    'revision': revision,
  };
}
