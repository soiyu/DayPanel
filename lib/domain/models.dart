// New DayPanel domain; no dependency on Flutter or the Loop schema.
class Day implements Comparable<Day> {
  Day(DateTime value) : date = DateTime(value.year, value.month, value.day);
  factory Day.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Invalid calendar date');
    }
    final day = Day(DateTime.parse(value));
    if (day.key != value || day.date.year < 1900 || day.date.year > 2200) {
      throw const FormatException('Invalid calendar date');
    }
    return day;
  }
  final DateTime date;
  String get key =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  Day plus(int days) => Day(DateTime(date.year, date.month, date.day + days));
  int daysSince(Day other) => DateTime.utc(date.year, date.month, date.day)
      .difference(
        DateTime.utc(other.date.year, other.date.month, other.date.day),
      )
      .inDays;
  Day get monday => plus(1 - date.weekday);
  @override
  int compareTo(Day other) => key.compareTo(other.key);
  @override
  bool operator ==(Object other) => other is Day && key == other.key;
  @override
  int get hashCode => key.hashCode;
}

enum HabitKind { check, quantity }

enum ScheduleKind { weekdays, interval, weekly }

enum HabitContext { anytime, morning, daytime, evening }

class HabitGroup {
  const HabitGroup({required this.id, required this.name, this.position = 0});
  final String id, name;
  final int position;
  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'position': position,
  };
  factory HabitGroup.fromMap(Map<String, Object?> m) => HabitGroup(
    id: m['id'] as String,
    name: m['name'] as String,
    position: m['position'] as int,
  );
}

class HabitPlan {
  const HabitPlan({
    required this.habitId,
    required this.effectiveDay,
    required this.target,
    required this.unit,
    this.schedule = ScheduleKind.weekdays,
    this.weekdays = 127,
    this.intervalDays = 1,
    this.weeklyGoal = 3,
  });
  final String habitId, unit;
  final Day effectiveDay;
  final int target, weekdays, intervalDays, weeklyGoal;
  final ScheduleKind schedule;
  factory HabitPlan.fromHabit(Habit h, Day day) => HabitPlan(
    habitId: h.id,
    effectiveDay: day,
    target: h.target,
    unit: h.unit,
    schedule: h.schedule,
    weekdays: h.weekdays,
    intervalDays: h.intervalDays,
    weeklyGoal: h.weeklyGoal,
  );
  Map<String, Object?> toMap() => {
    'habit_id': habitId,
    'effective_day': effectiveDay.key,
    'target': target,
    'unit': unit,
    'schedule': schedule.name,
    'weekdays': weekdays,
    'interval_days': intervalDays,
    'weekly_goal': weeklyGoal,
  };
  factory HabitPlan.fromMap(Map<String, Object?> m) => HabitPlan(
    habitId: m['habit_id'] as String,
    effectiveDay: Day.parse(m['effective_day'] as String),
    target: m['target'] as int,
    unit: m['unit'] as String,
    schedule: ScheduleKind.values.byName(m['schedule'] as String),
    weekdays: m['weekdays'] as int,
    intervalDays: m['interval_days'] as int,
    weeklyGoal: m['weekly_goal'] as int,
  );
  bool scheduled(Day day) =>
      day.compareTo(effectiveDay) >= 0 &&
      switch (schedule) {
        ScheduleKind.weekdays =>
          (weekdays & (1 << (day.date.weekday - 1))) != 0,
        ScheduleKind.interval =>
          day.daysSince(effectiveDay) % intervalDays == 0,
        ScheduleKind.weekly => true,
      };
  bool sameRules(HabitPlan other) =>
      target == other.target &&
      unit == other.unit &&
      schedule == other.schedule &&
      weekdays == other.weekdays &&
      intervalDays == other.intervalDays &&
      weeklyGoal == other.weeklyGoal;
}

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
    this.context = HabitContext.anytime,
    this.groupId,
    this.position = 0,
    this.schedule = ScheduleKind.weekdays,
    this.intervalDays = 1,
    this.weeklyGoal = 3,
  });
  final String id, title, unit;
  final HabitKind kind;
  final Day startDay;
  final int target, weekdays, icon;
  final bool archived;
  final HabitContext context;
  final String? groupId;
  final int position, intervalDays, weeklyGoal;
  final ScheduleKind schedule;
  bool scheduled(Day day) =>
      !archived &&
      day.compareTo(startDay) >= 0 &&
      HabitPlan.fromHabit(this, startDay).scheduled(day);
  Habit withPlan(HabitPlan plan) => Habit.fromMap({
    ...toMap(),
    'target': plan.target,
    'unit': plan.unit,
    'weekdays': plan.weekdays,
    'schedule': plan.schedule.name,
    'interval_days': plan.intervalDays,
    'weekly_goal': plan.weeklyGoal,
  });
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
    'context': context.name,
    'group_id': groupId,
    'position': position,
    'schedule': schedule.name,
    'interval_days': intervalDays,
    'weekly_goal': weeklyGoal,
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
    context: HabitContext.values.byName(m['context'] as String? ?? 'anytime'),
    groupId: m['group_id'] as String?,
    position: m['position'] as int? ?? 0,
    schedule: ScheduleKind.values.byName(
      m['schedule'] as String? ?? 'weekdays',
    ),
    intervalDays: m['interval_days'] as int? ?? 1,
    weeklyGoal: m['weekly_goal'] as int? ?? 3,
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
    this.resident = false,
    this.startDay,
    this.archived = false,
  });
  final String id, title;
  final Day? dueDay, completedDay;
  final bool resident, archived;
  final Day? startDay;
  bool get done => completedDay != null;
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'due_day': dueDay?.key,
    'completed_day': completedDay?.key,
    'resident': resident ? 1 : 0,
    'start_day': startDay?.key,
    'archived': archived ? 1 : 0,
  };
  factory SmallTask.fromMap(Map<String, Object?> m) => SmallTask(
    id: m['id'] as String,
    title: m['title'] as String,
    dueDay: m['due_day'] == null ? null : Day.parse(m['due_day'] as String),
    completedDay: m['completed_day'] == null
        ? null
        : Day.parse(m['completed_day'] as String),
    resident: m['resident'] == 1,
    startDay: m['start_day'] == null
        ? null
        : Day.parse(m['start_day'] as String),
    archived: m['archived'] == 1,
  );
}

class TaskEntry {
  const TaskEntry({required this.taskId, required this.day});
  final String taskId;
  final Day day;
  Map<String, Object?> toMap() => {'task_id': taskId, 'day': day.key};
  factory TaskEntry.fromMap(Map<String, Object?> m) => TaskEntry(
    taskId: m['task_id'] as String,
    day: Day.parse(m['day'] as String),
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
