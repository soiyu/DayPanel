import 'dart:convert';
import 'dart:typed_data';
import 'backup.dart';
import 'models.dart';

/// One user fact per row; neutral English headers work across spreadsheet locales.
/// All user text is quoted and formula-looking cells are escaped.
Uint8List readableCsv(BackupSnapshot snapshot) {
  String cell(Object? v) {
    var s = v?.toString() ?? '';
    if (RegExp(r'^[\s]*[=+@-]').hasMatch(s) && v is! num) s = "'$s";
    return '"${s.replaceAll('"', '""')}"';
  }

  final out = StringBuffer('\uFEFF');
  void row(List<Object?> cells) =>
      out.write('${cells.map(cell).join(',')}\r\n');
  row([
    'type',
    'id',
    'title',
    'date',
    'time',
    'value',
    'unit',
    'note',
    'status',
  ]);
  final t = snapshot.tables;
  final habits = {for (final h in t['habits']!) h['id']: h};
  final tasks = {for (final task in t['tasks']!) task['id']: task};
  String unit(Object? id, String day) {
    final plans =
        t['plans']!
            .where(
              (p) =>
                  p['habit_id'] == id &&
                  (p['effective_day'] as String).compareTo(day) <= 0,
            )
            .toList()
          ..sort(
            (a, b) => (a['effective_day'] as String).compareTo(
              b['effective_day'] as String,
            ),
          );
    return plans.isEmpty ? '' : plans.last['unit'] as String;
  }

  for (final h in habits.values) {
    row([
      'habit',
      h['id'],
      h['title'],
      h['start_day'],
      '',
      quantityText(h['target'] as int),
      h['unit'],
      h['schedule'],
      h['archived'] == 1 ? 'archived' : 'active',
    ]);
  }
  for (final e in t['entries']!) {
    row([
      'daily_total',
      e['habit_id'],
      habits[e['habit_id']]?['title'],
      e['day'],
      '',
      quantityText(e['value'] as int),
      unit(e['habit_id'], e['day'] as String),
      '',
      'recorded',
    ]);
  }
  for (final e in t['record_events']!.where((e) => e['deleted'] == 0)) {
    final minute = e['minute'] as int?;
    final value = e['value'] as int;
    row([
      e['kind'],
      e['id'],
      habits[e['habit_id']]?['title'],
      e['day'],
      minute == null
          ? ''
          : '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}',
      '${value < 0 ? '-' : ''}${quantityText(value.abs())}',
      unit(e['habit_id'], e['day'] as String),
      e['note'],
      'recorded',
    ]);
  }
  for (final task in tasks.values) {
    row([
      task['resident'] == 1 ? 'resident_task' : 'one_time_task',
      task['id'],
      task['title'],
      task['completed_day'] ?? task['due_day'] ?? task['start_day'],
      '',
      '',
      '',
      task['due_day'] == null ? '' : 'planned: ${task['due_day']}',
      task['archived'] == 1
          ? 'archived'
          : task['completed_day'] == null
          ? 'open'
          : 'completed',
    ]);
  }
  for (final e in t['task_entries']!) {
    row([
      'task_completion',
      e['task_id'],
      tasks[e['task_id']]?['title'],
      e['day'],
      '',
      '',
      '',
      '',
      'completed',
    ]);
  }
  for (final n in t['notes']!) {
    row([
      'journal',
      n['id'],
      habits[n['habit_id']]?['title'],
      n['day'],
      '',
      '',
      '',
      n['body'],
      'saved',
    ]);
  }
  for (final card in t['cards']!) {
    row([
      'daily_card',
      card['day'],
      'Artwork ${card['artwork']}',
      card['day'],
      '',
      '',
      '',
      card['reflection'],
      card['favorite'] == 1 ? 'favorite' : 'earned',
    ]);
  }
  return Uint8List.fromList(utf8.encode(out.toString()));
}
