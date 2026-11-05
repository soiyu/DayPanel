import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'models.dart';

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
    'notes',
    'settings',
  ];
  final DateTime createdAt;
  final Map<String, List<Map<String, Object?>>> tables;
  int count(String table) => tables[table]!.length;
  Uint8List encode() {
    final payload = jsonEncode({
      'schema': 2,
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
      if (content['schema'] != 2) throw const BackupInvalid();
      final created = DateTime.parse(content['created_at'] as String);
      if (!created.isUtc || created.year < 1900 || created.year > 2200) {
        throw const BackupInvalid();
      }
      final raw = content['tables'] as Map<String, dynamic>;
      _keys(raw, tableNames.toSet());
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
      _int(m, 'icon', 0, 5);
      _int(m, 'archived', 0, 1);
      _int(m, 'position', 0, 1000000);
      _int(m, 'interval_days', 1, 365);
      _int(m, 'weekly_goal', 1, 7);
      if (habitIds.containsKey(id) ||
          (m['group_id'] != null && !groupIds.contains(m['group_id']))) {
        throw const BackupInvalid();
      }
      final h = Habit.fromMap(m);
      if (h.kind == HabitKind.check && h.target != 1000) {
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
          (h.kind == HabitKind.check && plan.target != 1000)) {
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
          !entryKeys.add('${m['habit_id']}/${d.key}')) {
        throw const BackupInvalid();
      }
    }
    final taskIds = <String>{};
    for (final m in t['tasks']!) {
      _keys(m, {'id', 'title', 'due_day', 'completed_day'});
      if (!taskIds.add(_text(m, 'id', 128))) throw const BackupInvalid();
      _text(m, 'title', 100);
      if (m['due_day'] != null) Day.parse(m['due_day'] as String);
      if (m['completed_day'] != null) Day.parse(m['completed_day'] as String);
    }
    final noteIds = <String>{};
    for (final m in t['notes']!) {
      _keys(m, {'id', 'body', 'day'});
      if (!noteIds.add(_text(m, 'id', 128))) throw const BackupInvalid();
      _text(m, 'body', 10000);
      Day.parse(m['day'] as String);
    }
    final settingKeys = <String>{};
    for (final m in t['settings']!) {
      _keys(m, {'key', 'value'});
      if (!settingKeys.add(m['key'] as String)) throw const BackupInvalid();
      if (m['key'] == 'theme' &&
          {'system', 'light', 'dark'}.contains(m['value'])) {
        continue;
      }
      if (m['key'] == 'locale' && {'system', 'en', 'zh'}.contains(m['value'])) {
        continue;
      }
      throw const BackupInvalid();
    }
  }
}
