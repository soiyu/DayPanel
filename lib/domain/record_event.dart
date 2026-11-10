import 'models.dart';

enum RecordEventKind { baseline, record, adjustment }

/// A saved local-date fact. Unknown times stay unknown across migration/restore.
class RecordEvent {
  const RecordEvent({
    required this.id,
    required this.habitId,
    required this.day,
    required this.value,
    this.minute,
    this.note = '',
    this.kind = RecordEventKind.record,
    this.revision = 0,
    this.deleted = false,
  });
  final String id, habitId, note;
  final Day day;
  final int value, revision;
  final int? minute;
  final RecordEventKind kind;
  final bool deleted;
  Map<String, Object?> toMap() => {
    'id': id,
    'habit_id': habitId,
    'day': day.key,
    'value': value,
    'minute': minute,
    'note': note,
    'kind': kind.name,
    'revision': revision,
    'deleted': deleted ? 1 : 0,
  };
  factory RecordEvent.fromMap(Map<String, Object?> m) => RecordEvent(
    id: m['id'] as String,
    habitId: m['habit_id'] as String,
    day: Day.parse(m['day'] as String),
    value: m['value'] as int,
    minute: m['minute'] as int?,
    note: m['note'] as String,
    kind: RecordEventKind.values.byName(m['kind'] as String),
    revision: m['revision'] as int,
    deleted: m['deleted'] == 1,
  );
}
