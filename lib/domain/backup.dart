import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'models.dart';
import 'record_event.dart';
import 'reminder.dart';
import 'achievement.dart';
import 'activity.dart';
import 'habit_break.dart';
import 'appearance.dart';

class BackupInvalid implements Exception {
  const BackupInvalid();
}

class BackupSnapshot {
  BackupSnapshot._(this.createdAt, this.tables);
  static const maxBytes = 8 * 1024 * 1024;
  static const tableNames = [
    'habit_groups',
    'habits',
    'plans',
    'entries',
    'tasks',
    'task_entries',
    'notes',
    'settings',
    'reminders',
    'cards',
    'habit_activity',
    'habit_breaks',
    'record_events',
  ];
  final DateTime createdAt;
  final Map<String, List<Map<String, Object?>>> tables;
  int count(String table) => tables[table]!.length;
  Uint8List encode() {
    final payload = jsonEncode({
      'schema': 12,
      'created_at': createdAt.toUtc().toIso8601String(),
      'tables': tables,
    });
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': 'daypanel-backup',
          'version': 1,
          'sha256': sha256.convert(utf8.encode(payload)).toString(),
          'payload': payload,
        }),
      ),
    );
    if (bytes.length > maxBytes) throw const BackupInvalid();
    return bytes;
  }

  static BackupSnapshot fromTables(
    Map<String, List<Map<String, Object?>>> tables,
    DateTime createdAt,
  ) {
    final candidate = BackupSnapshot._(createdAt, tables);
    return decode(candidate.encode());
  }

  static BackupSnapshot decode(List<int> bytes) {
    try {
      if (bytes.isEmpty || bytes.length > maxBytes) throw const BackupInvalid();
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      _keys(envelope, {'format', 'version', 'sha256', 'payload'});
      if (envelope['format'] != 'daypanel-backup' ||
          envelope['version'] != 1 ||
          envelope['payload'] is! String) {
        throw const BackupInvalid();
      }
      final payload = envelope['payload'] as String;
      if (sha256.convert(utf8.encode(payload)).toString() !=
          envelope['sha256']) {
        throw const BackupInvalid();
      }
      final content = jsonDecode(payload) as Map<String, dynamic>;
      _keys(content, {'schema', 'created_at', 'tables'});
      if (!{2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}.contains(content['schema'])) {
        throw const BackupInvalid();
      }
      final created = DateTime.parse(content['created_at'] as String);
      if (!created.isUtc || created.year < 1900 || created.year > 2200) {
        throw const BackupInvalid();
      }
      final raw = content['tables'] as Map<String, dynamic>;
      final schema = content['schema'] as int;
      // A lower schema must not smuggle a newer enum, including snapshots of
      // deleted habits that survive only in already earned card evidence.
      if (schema < 11) {
        for (final habit in raw['habits'] as List) {
          if ((habit as Map)['kind'] == HabitKind.count.name) {
            throw const BackupInvalid();
          }
        }
        if (schema >= 6) {
          for (final card in raw['cards'] as List) {
            final evidence =
                jsonDecode((card as Map)['evidence'] as String) as List;
            if (evidence.any(
              (item) => (item as Map)['kind'] == HabitKind.count.name,
            )) {
              throw const BackupInvalid();
            }
          }
        }
      }
      if (schema < 12) {
        for (final h in raw['habits'] as List) {
          if ((h['icon'] as int) > 23) throw const BackupInvalid();
        }
        if ((raw['settings'] as List).any(
          (r) =>
              r['key'] == 'palette' &&
              ['apricot', 'coast'].contains(r['value']),
        )) {
          throw const BackupInvalid();
        }
        for (final name in ['habits', 'plans']) {
          if ((raw[name] as List).any((r) => r['schedule'] == 'weeklyTotal')) {
            throw const BackupInvalid();
          }
        }
      }
      _keys(
        raw,
        tableNames
            .where(
              (n) =>
                  (schema >= 3 || n != 'reminders') &&
                  (schema >= 4 || n != 'task_entries') &&
                  (schema >= 6 || n != 'cards') &&
                  (schema >= 7 || n != 'habit_activity') &&
                  (schema >= 9 || n != 'habit_breaks') &&
                  (schema >= 12 || n != 'record_events'),
            )
            .toSet(),
      );
      if (schema < 9) raw['habit_breaks'] = <Object>[];
      if (schema < 8) {
        for (final row in raw['habits'] as List) {
          if ((row as Map).containsKey('color') || row.containsKey('frame')) {
            throw const BackupInvalid();
          }
          _int(row, 'icon', 0, 5);
          row['color'] = 'auto';
          row['frame'] = 'auto';
        }
        // New preference identifiers are only valid in schema8.
        for (final row in raw['settings'] as List) {
          if (['palette', 'font', 'icon_frame'].contains(row['key'])) {
            throw const BackupInvalid();
          }
        }
      }
      if (schema < 3) raw['reminders'] = <Object>[];
      if (schema < 6) raw['cards'] = <Object>[];
      if (schema < 7) {
        final date = Day(created.toLocal());
        raw['habit_activity'] = [
          for (final h in raw['habits'] as List)
            {
              'habit_id': h['id'],
              'day': (h['start_day'] as String).compareTo(date.key) > 0
                  ? h['start_day']
                  : date.key,
              'archived': h['archived'],
            },
        ];
      }
      if (schema < 4) {
        raw['task_entries'] = <Object>[];
        for (final row in raw['tasks'] as List) {
          _keys(row as Map, {'id', 'title', 'due_day', 'completed_day'});
          row['resident'] = 0;
          row['start_day'] = null;
          row['archived'] = 0;
        }
      }
      if (schema < 5) {
        for (final row in raw['notes'] as List) {
          _keys(row as Map, {'id', 'body', 'day'});
          row['habit_id'] = null;
        }
      }
      if (schema < 12) {
        final numericIds = {
          for (final h in raw['habits'] as List)
            if (h['kind'] != 'check') h['id'],
        };
        var index = 0;
        raw['record_events'] = [
          for (final e in raw['entries'] as List)
            if (numericIds.contains(e['habit_id']))
              {
                'id': 'legacy-baseline-${index++}',
                'habit_id': e['habit_id'],
                'day': e['day'],
                'value': e['value'],
                'minute': null,
                'note': '',
                'kind': 'baseline',
                'revision': 0,
                'deleted': 0,
              },
        ];
      }
      final tables = <String, List<Map<String, Object?>>>{};
      var total = 0;
      for (final name in tableNames) {
        final rows = raw[name] as List;
        total += rows.length;
        if (total > 100000) throw const BackupInvalid();
        tables[name] = List.unmodifiable(
          rows.map(
            (row) => Map<String, Object?>.unmodifiable(
              Map<String, Object?>.from(row as Map),
            ),
          ),
        );
      }
      _validate(tables);
      return BackupSnapshot._(created, Map.unmodifiable(tables));
    } catch (_) {
      throw const BackupInvalid();
    }
  }

  static void _keys(Map m, Set<String> names) {
    if (m.length != names.length || !names.containsAll(m.keys)) {
      throw const BackupInvalid();
    }
  }

  static String _text(Map m, String key, int max, {bool empty = false}) {
    final v = m[key];
    if (v is! String || v.length > max || (!empty && v.trim().isEmpty)) {
      throw const BackupInvalid();
    }
    return v;
  }

  static int _int(Map m, String key, int min, int max) {
    final v = m[key];
    if (v is! int || v < min || v > max) throw const BackupInvalid();
    return v;
  }

  static void _validate(Map<String, List<Map<String, Object?>>> t) {
    final groupIds = <String>{};
    final habitIds = <String, Habit>{};
    final groupNames = <String>{};
    for (final m in t['habit_groups']!) {
      _keys(m, {'id', 'name', 'position'});
      if (!groupIds.add(_text(m, 'id', 128)) ||
          !groupNames.add(_text(m, 'name', 40).toLowerCase())) {
        throw const BackupInvalid();
      }
      _int(m, 'position', 0, 1000000);
    }
    for (final m in t['habits']!) {
      _keys(m, {
        'id',
        'title',
        'kind',
        'start_day',
        'target',
        'unit',
        'weekdays',
        'icon',
        'color',
        'frame',
        'archived',
        'context',
        'group_id',
        'position',
        'schedule',
        'interval_days',
        'weekly_goal',
      });
      final id = _text(m, 'id', 128);
      _text(m, 'title', 100);
      _text(m, 'unit', 12, empty: true);
      _int(m, 'target', 1, 999999999999);
      _int(m, 'weekdays', 1, 127);
      _int(m, 'icon', 0, Appearance.iconCount - 1);
      if (!Appearance.habitColors.contains(m['color']) ||
          !Appearance.habitFrames.contains(m['frame'])) {
        throw const BackupInvalid();
      }
      _int(m, 'archived', 0, 1);
      _int(m, 'position', 0, 1000000);
      _int(m, 'interval_days', 1, 365);
      _int(m, 'weekly_goal', 1, 7);
      if (habitIds.containsKey(id) ||
          (m['group_id'] != null && !groupIds.contains(m['group_id']))) {
        throw const BackupInvalid();
      }
      final h = Habit.fromMap(m);
      if ((h.kind == HabitKind.check &&
              (h.target != 1000 || h.schedule == ScheduleKind.weeklyTotal)) ||
          (h.kind == HabitKind.count && h.target % 1000 != 0)) {
        throw const BackupInvalid();
      }
      habitIds[id] = h;
    }
    final planKeys = <String>{};
    final first = <String, Day>{};
    final latest = <String, HabitPlan>{};
    for (final m in t['plans']!) {
      _keys(m, {
        'habit_id',
        'effective_day',
        'target',
        'unit',
        'schedule',
        'weekdays',
        'interval_days',
        'weekly_goal',
      });
      _int(m, 'target', 1, 999999999999);
      _int(m, 'weekdays', 1, 127);
      _int(m, 'interval_days', 1, 365);
      _int(m, 'weekly_goal', 1, 7);
      _text(m, 'unit', 12, empty: true);
      final plan = HabitPlan.fromMap(m);
      final h = habitIds[plan.habitId];
      if (h == null ||
          plan.effectiveDay.compareTo(h.startDay) < 0 ||
          !planKeys.add('${plan.habitId}/${plan.effectiveDay.key}') ||
          (h.kind == HabitKind.check &&
              (plan.target != 1000 ||
                  plan.schedule == ScheduleKind.weeklyTotal)) ||
          (h.kind == HabitKind.count && plan.target % 1000 != 0)) {
        throw const BackupInvalid();
      }
      if (first[h.id] == null ||
          plan.effectiveDay.compareTo(first[h.id]!) < 0) {
        first[h.id] = plan.effectiveDay;
      }
      if (latest[h.id] == null ||
          plan.effectiveDay.compareTo(latest[h.id]!.effectiveDay) > 0) {
        latest[h.id] = plan;
      }
    }
    for (final h in habitIds.values) {
      if (first[h.id] != h.startDay ||
          !latest[h.id]!.sameRules(HabitPlan.fromHabit(h, h.startDay))) {
        throw const BackupInvalid();
      }
    }
    final entryKeys = <String>{};
    for (final m in t['entries']!) {
      _keys(m, {'habit_id', 'day', 'value'});
      final h = habitIds[m['habit_id']];
      final d = Day.parse(m['day'] as String);
      final v = _int(m, 'value', 0, 999999999999);
      if (h == null ||
          d.compareTo(h.startDay) < 0 ||
          (h.kind == HabitKind.check && v != 0 && v != 1000) ||
          (h.kind == HabitKind.count && v % 1000 != 0) ||
          !entryKeys.add('${m['habit_id']}/${d.key}')) {
        throw const BackupInvalid();
      }
    }
    final eventIds = <String>{};
    final totals = <String, int>{};
    for (final m in t['record_events']!) {
      _keys(m, {
        'id',
        'habit_id',
        'day',
        'value',
        'minute',
        'note',
        'kind',
        'revision',
        'deleted',
      });
      if (!eventIds.add(_text(m, 'id', 128))) throw const BackupInvalid();
      _text(m, 'note', 500, empty: true);
      _int(m, 'revision', 0, 9007199254740991);
      _int(m, 'deleted', 0, 1);
      _int(m, 'value', -999999999999, 999999999999);
      if (m['minute'] != null) _int(m, 'minute', 0, 1439);
      final e = RecordEvent.fromMap(m);
      final h = habitIds[e.habitId];
      if (h == null ||
          !h.kind.isNumeric ||
          e.day.compareTo(h.startDay) < 0 ||
          (h.kind == HabitKind.count && e.value % 1000 != 0) ||
          (!e.deleted && e.kind == RecordEventKind.record && e.value <= 0) ||
          (e.kind != RecordEventKind.adjustment && e.value < 0) ||
          (e.kind != RecordEventKind.record && e.minute != null)) {
        throw const BackupInvalid();
      }
      if (!e.deleted) {
        totals.update(
          '${e.habitId}/${e.day.key}',
          (v) => v + e.value,
          ifAbsent: () => e.value,
        );
      }
    }
    final numericEntries = {
      for (final e in t['entries']!)
        if (habitIds[e['habit_id']]!.kind.isNumeric)
          '${e['habit_id']}/${e['day']}': e['value'] as int,
    };
    if (totals.length != numericEntries.length ||
        totals.entries.any((e) => numericEntries[e.key] != e.value)) {
      throw const BackupInvalid();
    }
    final taskIds = <String, SmallTask>{};
    for (final m in t['tasks']!) {
      _keys(m, {
        'id',
        'title',
        'due_day',
        'completed_day',
        'resident',
        'start_day',
        'archived',
      });
      final id = _text(m, 'id', 128);
      if (taskIds.containsKey(id)) throw const BackupInvalid();
      _text(m, 'title', 100);
      _int(m, 'resident', 0, 1);
      _int(m, 'archived', 0, 1);
      if (m['due_day'] != null) Day.parse(m['due_day'] as String);
      if (m['completed_day'] != null) Day.parse(m['completed_day'] as String);
      final task = SmallTask.fromMap(m);
      if (task.resident
          ? (task.startDay == null ||
                task.dueDay != null ||
                task.completedDay != null)
          : (task.startDay != null || task.archived)) {
        throw const BackupInvalid();
      }
      taskIds[id] = task;
    }
    final taskEntryKeys = <String>{};
    for (final m in t['task_entries']!) {
      _keys(m, {'task_id', 'day'});
      final task = taskIds[m['task_id']];
      final date = Day.parse(m['day'] as String);
      if (task == null ||
          !task.resident ||
          date.compareTo(task.startDay!) < 0 ||
          !taskEntryKeys.add('${task.id}/${date.key}')) {
        throw const BackupInvalid();
      }
    }
    final noteIds = <String>{};
    for (final m in t['notes']!) {
      _keys(m, {'id', 'body', 'day', 'habit_id'});
      if (!noteIds.add(_text(m, 'id', 128))) throw const BackupInvalid();
      _text(m, 'body', 10000);
      Day.parse(m['day'] as String);
      if (m['habit_id'] != null && !habitIds.containsKey(m['habit_id'])) {
        throw const BackupInvalid();
      }
    }
    final activityKeys = <String>{};
    final latestActivity = <String, HabitActivity>{};
    for (final m in t['habit_activity']!) {
      _keys(m, {'habit_id', 'day', 'archived'});
      _int(m, 'archived', 0, 1);
      final a = HabitActivity.fromMap(m);
      final h = habitIds[a.habitId];
      if (h == null ||
          a.day.compareTo(h.startDay) < 0 ||
          !activityKeys.add('${a.habitId}/${a.day.key}')) {
        throw const BackupInvalid();
      }
      if (latestActivity[a.habitId] == null ||
          a.day.compareTo(latestActivity[a.habitId]!.day) > 0) {
        latestActivity[a.habitId] = a;
      }
    }
    for (final h in habitIds.values) {
      if (latestActivity[h.id]?.archived != h.archived) {
        throw const BackupInvalid();
      }
    }
    final breakIds = <String>{};
    final rests = <String, List<HabitBreak>>{};
    for (final m in t['habit_breaks']!) {
      _keys(m, {'id', 'habit_id', 'start_day', 'end_day', 'kind'});
      final b = HabitBreak.fromMap(m);
      final h = habitIds[b.habitId];
      if (!b.valid ||
          h == null ||
          b.start.compareTo(h.startDay) < 0 ||
          !breakIds.add(b.id)) {
        throw const BackupInvalid();
      }
      final prior = rests.putIfAbsent(b.habitId, () => []);
      if (prior.any(b.overlaps)) throw const BackupInvalid();
      prior.add(b);
      if (b.kind == BreakKind.skip &&
          entryKeys.contains('${b.habitId}/${b.start.key}')) {
        throw const BackupInvalid();
      }
    }
    final cardDays = <Day>{};
    for (final m in t['cards']!) {
      final card = AchievementCard.fromMap(m);
      if (!cardDays.add(card.day)) throw const BackupInvalid();
    }
    final settingKeys = <String>{};
    final reminderIds = <String>{};
    for (final m in t['reminders']!) {
      _keys(m, {'habit_id', 'enabled', 'minutes', 'revision'});
      _int(m, 'enabled', 0, 1);
      _int(m, 'revision', 0, 2147483647);
      _text(m, 'minutes', 100);
      final r = HabitReminder.fromMap(m);
      if (!r.valid ||
          !habitIds.containsKey(r.habitId) ||
          !reminderIds.add(r.habitId)) {
        throw const BackupInvalid();
      }
    }
    for (final m in t['settings']!) {
      _keys(m, {'key', 'value'});
      if (!settingKeys.add(m['key'] as String)) throw const BackupInvalid();
      if (!Appearance.validPreference(m['key'] as String, m['value'])) {
        throw const BackupInvalid();
      }
    }
  }
}
