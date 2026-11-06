import 'models.dart';

enum BreakKind { pause, vacation, skip }

class HabitBreak {
  const HabitBreak({
    required this.id,
    required this.habitId,
    required this.start,
    required this.kind,
    this.end,
  });
  final String id, habitId;
  final Day start;
  final Day? end;
  final BreakKind kind;
  bool contains(Day day) =>
      day.compareTo(start) >= 0 && (end == null || day.compareTo(end!) <= 0);
  bool overlaps(HabitBreak other) =>
      (end == null || other.start.compareTo(end!) <= 0) &&
      (other.end == null || start.compareTo(other.end!) <= 0);
  bool get valid =>
      id.isNotEmpty &&
      id.length <= 128 &&
      habitId.isNotEmpty &&
      (end == null ? kind == BreakKind.pause : end!.compareTo(start) >= 0) &&
      (kind != BreakKind.skip || end == start) &&
      (kind != BreakKind.vacation ||
          (end != null && end!.daysSince(start) < 365));
  Map<String, Object?> toMap() => {
    'id': id,
    'habit_id': habitId,
    'start_day': start.key,
    'end_day': end?.key,
    'kind': kind.name,
  };
  factory HabitBreak.fromMap(Map<String, Object?> m) => HabitBreak(
    id: m['id'] as String,
    habitId: m['habit_id'] as String,
    start: Day.parse(m['start_day'] as String),
    end: m['end_day'] == null ? null : Day.parse(m['end_day'] as String),
    kind: BreakKind.values.byName(m['kind'] as String),
  );
}

HabitBreak? breakOn(Iterable<HabitBreak> breaks, String id, Day day) =>
    breaks.where((b) => b.habitId == id && b.contains(day)).firstOrNull;
