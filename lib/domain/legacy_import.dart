import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'models.dart';
import 'backup.dart';
import 'activity.dart';

class LegacyInvalid implements Exception {
  const LegacyInvalid();
}

/// New schedule chosen explicitly when the source uses rolling frequency.
class LegacySchedule {
  const LegacySchedule(this.kind, [this.count = 1]);
  final ScheduleKind kind;
  final int count;
  bool get valid => switch (kind) {
    ScheduleKind.weekdays => count == 1,
    ScheduleKind.weekly => count >= 1 && count <= 7,
    ScheduleKind.interval => count >= 1 && count <= 365,
  };
}

class LegacyHabit {
  LegacyHabit({
    required this.sourceId,
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    required this.unit,
    required this.numerator,
    required this.denominator,
    required this.archived,
    required this.details,
    required this.unsupported,
    required List<LegacyEntry> entries,
  }) : entries = List.unmodifiable(entries);
  final int sourceId, type, numerator, denominator;
  final String id, name, unit, details;
  final int? target;
  final bool archived;
  final String? unsupported;
  final List<LegacyEntry> entries;
  bool get daily => numerator == denominator;
  int get records => entries.where((e) => e.value != null).length;
  int get skipped => entries.where((e) => e.skipped).length;
  int get ignored => entries.where((e) => e.ignored).length;
  int get notes =>
      1 + entries.where((e) => e.notes.trim().isNotEmpty || e.skipped).length;
}

class LegacyEntry {
  const LegacyEntry(
    this.day,
    this.value,
    this.notes, {
    this.skipped = false,
    this.ignored = false,
  });
  final Day day;
  final int? value;
  final String notes;
  final bool skipped, ignored;
}

class LegacyImport {
  LegacyImport._(this.version, this.day, List<LegacyHabit> habits)
    : habits = List.unmodifiable(habits);
  final int version;
  final Day day;
  final List<LegacyHabit> habits;
  static String identity(Object data) =>
      sha256.convert(utf8.encode(jsonEncode(data))).toString();

  static int? targetThousandths(String text) {
    final match = RegExp(
      r'^([0-9]+)(?:\.([0-9]+))?(?:[eE]([+-]?[0-9]+))?$',
    ).firstMatch(text);
    if (match == null || text.length > 60) return null;
    final fraction = match[2] ?? '';
    final exponent = int.tryParse(match[3] ?? '0');
    if (exponent == null || exponent.abs() > 20) return null;
    final digits = BigInt.parse('${match[1]}$fraction');
    final shift = 3 + exponent - fraction.length;
    final power = BigInt.from(10).pow(shift.abs());
    if (shift < 0 && digits.remainder(power) != BigInt.zero) return null;
    final value = shift < 0 ? digits ~/ power : digits * power;
    return value > BigInt.zero && value <= BigInt.from(999999999999)
        ? value.toInt()
        : null;
  }

  factory LegacyImport.decode(Map<Object?, Object?> raw, {required Day today}) {
    try {
      final version = _integer(raw['version'], 21, 25);
      final hs = raw['habits'] as List;
      final es = raw['entries'] as List;
      if (hs.length > 1000 || es.length > 50000) throw const LegacyInvalid();
      final ids = <int>{};
      final identities = <String>{};
      final byId = <int, Map>{};
      for (final value in hs) {
        final h = value as Map;
        final id = _integer(h['id'], 0, 9223372036854775807);
        if (!ids.add(id)) throw const LegacyInvalid();
        _integer(h['type'], 0, 1);
        _integer(h['target_type'], 0, 1);
        _integer(h['archived'], 0, 1);
        _integer(h['position'], 0, 2147483647);
        final n = _integer(h['numerator'], 1, 1000000);
        final d = _integer(h['denominator'], 1, 1000000);
        if (n > d) throw const LegacyInvalid();
        for (final key in [
          'name',
          'description',
          'question',
          'unit',
          'uuid',
          'target',
        ]) {
          if (h[key] is! String || (h[key] as String).length > 10000) {
            throw const LegacyInvalid();
          }
        }
        if ((h['name'] as String).trim().isEmpty) throw const LegacyInvalid();
        byId[id] = h;
      }
      final entries = <int, List<LegacyEntry>>{};
      final keys = <String>{};
      for (final value in es) {
        final e = value as Map;
        final id = _integer(e['habit'], 0, 9223372036854775807);
        final h = byId[id];
        if (h == null) throw const LegacyInvalid();
        final timestamp = e['timestamp'];
        if (timestamp is! int || timestamp % 86400000 != 0) {
          throw const LegacyInvalid();
        }
        final utc = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
        final day = Day.parse(
          '${utc.year.toString().padLeft(4, '0')}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}',
        );
        if (day.compareTo(today) > 0 || !keys.add('$id/${day.key}')) {
          throw const LegacyInvalid();
        }
        final v = _integer(e['value'], -1, h['type'] == 0 ? 3 : 999999999999);
        final note = e['notes'];
        if (note is! String || note.length > 9500) throw const LegacyInvalid();
        final check = h['type'] == 0;
        entries
            .putIfAbsent(id, () => [])
            .add(
              LegacyEntry(
                day,
                check
                    ? (v == 2
                          ? 1000
                          : v == 0
                          ? 0
                          : null)
                    : (v == -1 ? null : v),
                note,
                skipped: check && v == 3,
                ignored: v == -1 || (check && v == 1),
              ),
            );
      }
      final result = <LegacyHabit>[];
      final sorted = byId.values.toList()
        ..sort((a, b) {
          final order = (a['position'] as int).compareTo(b['position'] as int);
          return order != 0
              ? order
              : (a['id'] as int).compareTo(b['id'] as int);
        });
      for (final h in sorted) {
        final sourceId = h['id'] as int;
        final uuid = (h['uuid'] as String).trim();
        final id =
            'loop-${identity(uuid.isEmpty ? [sourceId, h['name'], h['type']] : uuid.toLowerCase())}';
        if (!identities.add(id)) throw const LegacyInvalid();
        final type = h['type'] as int;
        final target = type == 0
            ? 1000
            : targetThousandths(h['target'] as String);
        final name = h['name'] as String;
        final unit = h['unit'] as String;
        final details = [
          h['question'],
          h['description'],
        ].where((s) => (s as String).trim().isNotEmpty).join('\n\n');
        if (details.length > 8500) throw const LegacyInvalid();
        final rows = entries[sourceId] ?? [];
        rows.sort((a, b) => a.day.compareTo(b.day));
        result.add(
          LegacyHabit(
            sourceId: sourceId,
            id: id,
            name: name,
            type: type,
            target: target,
            unit: unit,
            numerator: h['numerator'] as int,
            denominator: h['denominator'] as int,
            archived: h['archived'] == 1,
            details: details,
            entries: rows,
            unsupported: name.length > 100 || unit.length > 12
                ? 'length'
                : type == 1 && h['target_type'] != 0
                ? 'atMost'
                : target == null
                ? 'target'
                : null,
          ),
        );
      }
      return LegacyImport._(version, today, result);
    } catch (_) {
      throw const LegacyInvalid();
    }
  }

  /// Pure conversion. Existing data is supplied at commit time, never from a
  /// stale preview. BackupSnapshot validates the entire combined dataset.
  BackupSnapshot appendTo(
    BackupSnapshot current,
    Map<String, LegacySchedule> selected, {
    required Day today,
    required bool chinese,
  }) {
    if (today != day || selected.isEmpty) throw const LegacyInvalid();
    final tables = {
      for (final e in current.tables.entries)
        e.key: e.value.map((r) => Map<String, Object?>.from(r)).toList(),
    };
    final existing = tables['habits']!.map((h) => h['id']).toSet();
    final available = {for (final h in habits) h.id: h};
    var position =
        tables['habits']!.fold<int>(
          -1,
          (p, h) => (h['position'] as int) > p ? h['position'] as int : p,
        ) +
        1;
    final noteIds = tables['notes']!.map((n) => n['id']).toSet();
    String noteId(String base) {
      var id = base;
      var suffix = 0;
      while (!noteIds.add(id)) {
        id = '$base-${++suffix}';
      }
      return id;
    }

    if (!available.keys.toSet().containsAll(selected.keys)) {
      throw const LegacyInvalid();
    }
    var added = 0;
    for (final choice in [
      for (final h in habits)
        if (selected.containsKey(h.id)) MapEntry(h.id, selected[h.id]!),
    ]) {
      final h = available[choice.key];
      final schedule = choice.value;
      if (h == null ||
          h.unsupported != null ||
          !schedule.valid ||
          (h.daily && schedule.kind != ScheduleKind.weekdays)) {
        throw const LegacyInvalid();
      }
      if (existing.contains(h.id)) continue;
      added++;
      final start = h.entries.isEmpty ? day : h.entries.first.day;
      final habit = Habit(
        id: h.id,
        title: h.name,
        kind: h.type == 0 ? HabitKind.check : HabitKind.quantity,
        startDay: start,
        target: h.target!,
        unit: h.type == 0 ? '' : h.unit,
        archived: h.archived,
        position: position++,
        schedule: schedule.kind,
        intervalDays: schedule.kind == ScheduleKind.interval
            ? schedule.count
            : 1,
        weeklyGoal: schedule.kind == ScheduleKind.weekly ? schedule.count : 3,
      );
      tables['habits']!.add(habit.toMap());
      tables['plans']!.add(HabitPlan.fromHabit(habit, start).toMap());
      if (schedule.kind == ScheduleKind.interval && start != day) {
        tables['plans']!.add(HabitPlan.fromHabit(habit, day).toMap());
      }
      tables['habit_activity']!.add(
        HabitActivity(habitId: h.id, day: day, archived: h.archived).toMap(),
      );
      final info = chinese
          ? '从 Loop 导入 · ${day.key}\n原频率 ${h.numerator}/${h.denominator}，目标 ${h.type == 0 ? '完成' : quantityText(h.target!)} ${h.unit}。\n历史计划与归档履历未知，导入前日期不计失败。提醒未导入，安排使用导入时确认的规则。'
          : 'Imported from Loop · ${day.key}\nSource frequency ${h.numerator}/${h.denominator}, target ${h.type == 0 ? 'check off' : quantityText(h.target!)} ${h.unit}.\nPast schedules and archive history are unknown; earlier days are not counted as failures. Reminders are not imported. The schedule is the one confirmed during import.';
      tables['notes']!.add(
        Note(
          id: noteId('${h.id}-source'),
          body: '$info${h.details.isEmpty ? '' : '\n\n${h.details}'}',
          day: day,
          habitId: h.id,
        ).toMap(),
      );
      for (final e in h.entries) {
        if (e.value != null) {
          tables['entries']!.add({
            'habit_id': h.id,
            'day': e.day.key,
            'value': e.value,
          });
        }
        if (e.notes.trim().isNotEmpty || e.skipped) {
          final prefix = e.skipped
              ? (chinese ? 'Loop 原记录：已跳过。' : 'Loop source record: skipped.')
              : '';
          tables['notes']!.add(
            Note(
              id: noteId('${h.id}-${e.day.key}'),
              body: [prefix, e.notes].where((s) => s.isNotEmpty).join('\n'),
              day: e.day,
              habitId: h.id,
            ).toMap(),
          );
        }
      }
    }
    if (added == 0) throw const LegacyInvalid();
    return BackupSnapshot.fromTables(tables, current.createdAt);
  }
}

int _integer(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) throw const LegacyInvalid();
  return value;
}
