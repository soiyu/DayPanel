import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/record_event.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/domain/statistics.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  final today = Day.parse('2026-11-15');
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => today.date);
    await store.saveHabit(
      Habit(
        id: 'h',
        title: 'Read',
        kind: HabitKind.quantity,
        startDay: today.monday,
        target: 10000,
        unit: 'pages',
      ),
      create: true,
      today: today,
    );
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  RecordEvent entry(String id, int amount, {Day? day}) => RecordEvent(
    id: id,
    habitId: 'h',
    day: day ?? today,
    value: amount,
    minute: 600,
    note: 'First',
  );
  test(
    'individual records idempotent submit, total correction and clear stay consistent',
    () async {
      final e = entry('a', 3000);
      await store.addRecordEvent(e, today: today);
      await store.addRecordEvent(e, today: today);
      await store.addRecordEvent(entry('b', 2000), today: today);
      expect((await store.entries()).single.value, 5000);
      await store.setRecord('h', today, 7000, today: today);
      expect(
        (await store.recordEvents())
            .map((e) => e.value)
            .reduce((a, b) => a + b),
        7000,
      );
      final snapshot = await store.exportSnapshot();
      expect(snapshot.count('record_events'), 3);
      await store.setRecord('h', today, null, today: today);
      expect(await store.entries(), isEmpty);
      expect((await store.recordEvents()).every((e) => e.deleted), isTrue);
      await expectLater(
        store.addRecordEvent(e, today: today),
        throwsA(isA<RecordRevisionConflict>()),
      );
      await store.exportSnapshot();
    },
  );
  test(
    'single record editing, stale ABA and negative resulting totals are rejected atomically',
    () async {
      await store.addRecordEvent(entry('a', 3000), today: today);
      await expectLater(
        store.reviseRecordEvent(
          entry('a', 0),
          today: today,
          expectedRevision: 0,
        ),
        throwsArgumentError,
      );
      expect((await store.entries()).single.value, 3000);
      await store.reviseRecordEvent(
        entry('a', 5000),
        today: today,
        expectedRevision: 0,
      );
      await store.reviseRecordEvent(
        entry('a', 3000),
        today: today,
        expectedRevision: 1,
      );
      await expectLater(
        store.reviseRecordEvent(
          entry('a', 6000),
          today: today,
          expectedRevision: 0,
        ),
        throwsA(isA<RecordRevisionConflict>()),
      );
      await store.setRecord('h', today, 1000, today: today);
      final before = (await store.exportSnapshot()).tables;
      await expectLater(
        store.reviseRecordEvent(
          RecordEvent(
            id: 'a',
            habitId: 'h',
            day: today,
            value: 3000,
            minute: 600,
            note: 'First',
            deleted: true,
          ),
          today: today,
          expectedRevision: 2,
        ),
        throwsArgumentError,
      );
      expect((await store.exportSnapshot()).tables, before);
    },
  );
  test('restore preserves events and prevents old page write', () async {
    await store.addRecordEvent(entry('a', 2000), today: today);
    final saved = await store.exportSnapshot();
    await store.setRecord('h', today, 8000, today: today);
    await store.restoreSnapshot(saved);
    await expectLater(
      store.inGeneration(
        0,
        () => store.addRecordEvent(entry('old', 1000), today: today),
      ),
      throwsStateError,
    );
    expect((await store.entries()).single.value, 2000);
    expect((await store.recordEvents()).single.id, 'a');
    await store.restoreSnapshot(
      (await store.recoverySnapshot())!,
      rollback: true,
    );
    expect((await store.entries()).single.value, 8000);
  });
  test('older schema11 total becomes honest unknown-time baseline', () async {
    await store.setRecord('h', today, 2500, today: today);
    final full = await store.exportSnapshot();
    final tables = {
      for (final e in full.tables.entries)
        if (e.key != 'record_events') e.key: e.value,
    };
    final payload = jsonEncode({
      'schema': 11,
      'created_at': DateTime.utc(2026, 11, 15).toIso8601String(),
      'tables': tables,
    });
    final old = BackupSnapshot.decode(
      utf8.encode(
        jsonEncode({
          'format': 'daypanel-backup',
          'version': 1,
          'sha256': sha256.convert(utf8.encode(payload)).toString(),
          'payload': payload,
        }),
      ),
    );
    final e = RecordEvent.fromMap(old.tables['record_events']!.single);
    expect(e.kind, RecordEventKind.baseline);
    expect(e.minute, isNull);
    expect(e.value, 2500);
  });
  test(
    'backup rejects forged aggregate and numeric event on check habit',
    () async {
      await store.addRecordEvent(entry('a', 2000), today: today);
      final snap = await store.exportSnapshot();
      final map = {
        for (final e in snap.tables.entries)
          e.key: e.value.map((r) => Map<String, Object?>.from(r)).toList(),
      };
      map['entries']!.single['value'] = 3000;
      expect(
        () => BackupSnapshot.fromTables(map, snap.createdAt),
        throwsA(isA<BackupInvalid>()),
      );
    },
  );
  test(
    'count fractions, future, before-start and rest event writes do not change tables',
    () async {
      await store.saveHabit(
        Habit(
          id: 'c',
          title: 'Practice',
          kind: HabitKind.count,
          startDay: today,
          target: 3000,
        ),
        create: true,
        today: today,
      );
      final before = (await store.exportSnapshot()).tables;
      for (final e in [
        RecordEvent(id: 'bad', habitId: 'c', day: today, value: 1500),
        entry('future', 1000, day: today.plus(1)),
        entry('old', 1000, day: today.monday.plus(-1)),
      ]) {
        await expectLater(
          store.addRecordEvent(e, today: today),
          throwsArgumentError,
        );
      }
      expect((await store.exportSnapshot()).tables, before);
    },
  );
  test(
    'weekly total sums values not achieved days, never qualifies for daily card',
    () async {
      await store.remove('habits', 'h');
      final h = Habit(
        id: 'w',
        title: 'Practice',
        kind: HabitKind.count,
        startDay: today.monday,
        target: 3000,
        unit: 'times',
        schedule: ScheduleKind.weeklyTotal,
      );
      await store.saveHabit(h, create: true, today: today);
      await store.setRecord('w', today, 3000, today: today);
      await app.load();
      expect(app.weekTotal(h, today), 3000);
      expect(app.dailyPlanned, isEmpty);
      expect(app.weeklyPlanned.length, 1);
      expect(app.canClaimCard, isFalse);
      expect(app.cards, isEmpty);
      final stats = HabitStatistics(
        h,
        app.plans,
        app.activity,
        app.entries,
        today,
      );
      final w = stats.weeks(today.monday, today).single;
      expect(w.achieved, 3000);
      expect(w.goal, 3000);
      expect(w.unit, 'times');
      expect(w.complete, isTrue);
    },
  );
  test(
    'weekly plan edits apply tomorrow and never combine units or partial versions',
    () async {
      final h = Habit(
        id: 'h',
        title: 'Read',
        kind: HabitKind.quantity,
        startDay: today.monday,
        target: 10000,
        unit: 'pages',
        schedule: ScheduleKind.weeklyTotal,
      );
      await store.saveHabit(h, today: today.monday); // new version Tuesday
      await store.setRecord('h', today.monday, 9000, today: today);
      await store.setRecord('h', today, 2000, today: today);
      await app.load();
      expect(app.weekTotal(h, today), 2000);
      final stats = HabitStatistics(
        app.habits.single,
        app.plans,
        app.activity,
        app.entries,
        today,
      );
      expect(stats.weeks(today.monday, today).single.eligible, isFalse);
      await store.exportSnapshot();
    },
  );
}
