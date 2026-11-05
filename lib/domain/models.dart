// New DayPanel domain; no dependency on Flutter or the Loop schema.
class Day implements Comparable<Day> {
  Day(DateTime value) : date = DateTime(value.year, value.month, value.day);
  factory Day.parse(String value) => Day(DateTime.parse(value));
  final DateTime date;
  String get key =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  Day plus(int days) => Day(DateTime(date.year, date.month, date.day + days));
  @override
  int compareTo(Day other) => key.compareTo(other.key);
  @override
  bool operator ==(Object other) => other is Day && key == other.key;
  @override
  int get hashCode => key.hashCode;
}

enum HabitKind { check, quantity }

class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.kind,
    required this.startDay,
    this.target = 1000,
    this.unit = '',
    this.weekdays = 127,
    this.icon = 0,
    this.archived = false,
  });
  final String id, title, unit;
  final HabitKind kind;
  final Day startDay;
  final int target, weekdays, icon;
  final bool archived;
  bool scheduled(Day day) =>
      !archived &&
      day.compareTo(startDay) >= 0 &&
      (weekdays & (1 << (day.date.weekday - 1))) != 0;
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'start_day': startDay.key,
    'target': target,
    'unit': unit,
    'weekdays': weekdays,
    'icon': icon,
    'archived': archived ? 1 : 0,
  };
  factory Habit.fromMap(Map<String, Object?> m) => Habit(
    id: m['id'] as String,
    title: m['title'] as String,
    kind: HabitKind.values.byName(m['kind'] as String),
    startDay: Day.parse(m['start_day'] as String),
    target: m['target'] as int,
    unit: m['unit'] as String,
    weekdays: m['weekdays'] as int,
    icon: m['icon'] as int,
    archived: m['archived'] == 1,
  );
}

class HabitEntry {
  const HabitEntry({
    required this.habitId,
    required this.day,
    required this.value,
  });
  final String habitId;
  final Day day;
  final int value;
}

class SmallTask {
  const SmallTask({
    required this.id,
    required this.title,
    this.dueDay,
    this.completedDay,
  });
  final String id, title;
  final Day? dueDay, completedDay;
  bool get done => completedDay != null;
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'due_day': dueDay?.key,
    'completed_day': completedDay?.key,
  };
  factory SmallTask.fromMap(Map<String, Object?> m) => SmallTask(
    id: m['id'] as String,
    title: m['title'] as String,
    dueDay: m['due_day'] == null ? null : Day.parse(m['due_day'] as String),
    completedDay: m['completed_day'] == null
        ? null
        : Day.parse(m['completed_day'] as String),
  );
}

class Note {
  const Note({required this.id, required this.body, required this.day});
  final String id, body;
  final Day day;
  Map<String, Object?> toMap() => {'id': id, 'body': body, 'day': day.key};
  factory Note.fromMap(Map<String, Object?> m) => Note(
    id: m['id'] as String,
    body: m['body'] as String,
    day: Day.parse(m['day'] as String),
  );
}

// Decimal input is exact. Group separators and scientific notation are not accepted.
int? parseQuantity(String input) {
  final normalized = input.trim().replaceAll('，', '.').replaceAll(',', '.');
  if (!RegExp(r'^\d{1,9}(\.\d{1,3})?$').hasMatch(normalized)) return null;
  final parts = normalized.split('.');
  return int.parse(parts[0]) * 1000 +
      (parts.length == 2 ? int.parse(parts[1].padRight(3, '0')) : 0);
}

String quantityText(int value) {
  final fraction = (value % 1000)
      .toString()
      .padLeft(3, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return '${value ~/ 1000}${fraction.isEmpty ? '' : '.$fraction'}';
}
