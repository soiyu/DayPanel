import 'dart:convert';
import 'models.dart';

class CardHabit {
  const CardHabit({
    required this.id,
    required this.title,
    required this.kind,
    required this.target,
    required this.unit,
    required this.value,
    required this.planDay,
  });
  final String id, title, unit;
  final HabitKind kind;
  final int target, value;
  final Day planDay;
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'target': target,
    'unit': unit,
    'value': value,
    'plan_day': planDay.key,
  };
  factory CardHabit.fromMap(Map<String, Object?> m) {
    _exact(m, {'id', 'title', 'kind', 'target', 'unit', 'value', 'plan_day'});
    final h = CardHabit(
      id: _text(m, 'id', 128),
      title: _text(m, 'title', 100),
      kind: HabitKind.values.byName(m['kind'] as String),
      target: _integer(m, 'target', 1, 999999999999),
      unit: _text(m, 'unit', 12, empty: true),
      value: _integer(m, 'value', 0, 999999999999),
      planDay: Day.parse(m['plan_day'] as String),
    );
    if (h.value < h.target ||
        (h.kind == HabitKind.check && (h.target != 1000 || h.value != 1000))) {
      throw const FormatException('Invalid card evidence');
    }
    return h;
  }
}

class AchievementCard {
  AchievementCard({
    required this.day,
    required this.artwork,
    required List<CardHabit> evidence,
    this.favorite = false,
    this.reflection = '',
  }) : evidence = List.unmodifiable(evidence);
  final Day day;
  final int artwork;
  final bool favorite;
  final String reflection;
  final List<CardHabit> evidence;
  static int artworkFor(Day day) => day.daysSince(Day(DateTime(2026))) % 6;
  Map<String, Object?> toMap() => {
    'day': day.key,
    'artwork': artwork,
    'favorite': favorite ? 1 : 0,
    'reflection': reflection,
    'evidence': jsonEncode(evidence.map((h) => h.toMap()).toList()),
  };
  factory AchievementCard.fromMap(Map<String, Object?> m) {
    _exact(m, {'day', 'artwork', 'favorite', 'reflection', 'evidence'});
    final day = Day.parse(m['day'] as String);
    final raw = jsonDecode(_text(m, 'evidence', 4 * 1024 * 1024)) as List;
    if (raw.isEmpty || raw.length > 10000) {
      throw const FormatException('Invalid card evidence');
    }
    final evidence = raw
        .map((v) => CardHabit.fromMap(Map<String, Object?>.from(v as Map)))
        .toList();
    if (evidence.map((h) => h.id).toSet().length != evidence.length ||
        evidence.any((h) => h.planDay.compareTo(day) > 0)) {
      throw const FormatException('Invalid card evidence');
    }
    final artwork = _integer(m, 'artwork', 0, 5);
    if (artwork != artworkFor(day)) {
      throw const FormatException('Invalid artwork for day');
    }
    return AchievementCard(
      day: day,
      artwork: artwork,
      evidence: evidence,
      favorite: _integer(m, 'favorite', 0, 1) == 1,
      reflection: _text(m, 'reflection', 10000, empty: true),
    );
  }
}

/// A snapshot of all daily obligations, independent of UI filters. Weekly
/// targets are flexible and deliberately never treated as daily obligations.
List<CardHabit>? completedCardEvidence(
  Day day,
  List<Habit> habits,
  List<HabitPlan> plans,
  List<HabitEntry> entries,
) {
  final result = <CardHabit>[];
  for (final h in habits) {
    if (h.archived || day.compareTo(h.startDay) < 0) continue;
    final versions =
        plans
            .where(
              (p) => p.habitId == h.id && p.effectiveDay.compareTo(day) <= 0,
            )
            .toList()
          ..sort((a, b) => a.effectiveDay.compareTo(b.effectiveDay));
    final p = versions.isEmpty
        ? HabitPlan.fromHabit(h, h.startDay)
        : versions.last;
    if (p.schedule == ScheduleKind.weekly || !p.scheduled(day)) continue;
    final value = entries
        .where((e) => e.habitId == h.id && e.day == day)
        .firstOrNull
        ?.value;
    if (value == null || value < p.target) return null;
    result.add(
      CardHabit(
        id: h.id,
        title: h.title,
        kind: h.kind,
        target: p.target,
        unit: p.unit,
        value: value,
        planDay: p.effectiveDay,
      ),
    );
  }
  return result.isEmpty ? null : result;
}

void _exact(Map m, Set<String> keys) {
  if (m.length != keys.length || !keys.containsAll(m.keys)) {
    throw const FormatException('Invalid card fields');
  }
}

String _text(Map m, String key, int max, {bool empty = false}) {
  final value = m[key];
  if (value is! String ||
      value.length > max ||
      (!empty && value.trim().isEmpty)) {
    throw const FormatException('Invalid card text');
  }
  return value;
}

int _integer(Map m, String key, int min, int max) {
  final value = m[key];
  if (value is! int || value < min || value > max) {
    throw const FormatException('Invalid card integer');
  }
  return value;
}
