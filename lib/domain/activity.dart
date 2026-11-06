import 'models.dart';

class HabitActivity {
  const HabitActivity({
    required this.habitId,
    required this.day,
    required this.archived,
  });
  final String habitId;
  final Day day;
  final bool archived;
  Map<String, Object?> toMap() => {
    'habit_id': habitId,
    'day': day.key,
    'archived': archived ? 1 : 0,
  };
  factory HabitActivity.fromMap(Map<String, Object?> m) => HabitActivity(
    habitId: m['habit_id'] as String,
    day: Day.parse(m['day'] as String),
    archived: m['archived'] == 1,
  );
}
