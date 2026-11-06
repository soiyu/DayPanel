import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory dir;
  final today = Day.parse('2026-11-05');
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('daypanel-plans-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/data.db',
    );
  });
  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });
  Habit base({ScheduleKind schedule = ScheduleKind.weekdays}) => Habit(
    id: 'h',
    title: 'Read',
    kind: HabitKind.quantity,
    startDay: today.plus(-7),
    target: 1000,
    unit: 'pages',
    schedule: schedule,
  );
  AppController controller() => AppController(store, clock: () => today.date);

  test('v1 upgrade preserves records and seeds plan/group/order metadata', () async {
    final path = '${dir.path}/legacy.db';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, v) async {
          await db.execute(
            'CREATE TABLE habits (id TEXT PRIMARY KEY,title TEXT,kind TEXT,start_day TEXT,target INTEGER,unit TEXT,weekdays INTEGER,icon INTEGER,archived INTEGER)',
          );
          await db.execute(
            'CREATE TABLE entries(habit_id TEXT,day TEXT,value INTEGER,PRIMARY KEY(habit_id,day))',
          );
          await db.execute(
            'CREATE TABLE tasks(id TEXT PRIMARY KEY,title TEXT,due_day TEXT,completed_day TEXT)',
          );
          await db.execute(
            'CREATE TABLE notes(id TEXT PRIMARY KEY,body TEXT,day TEXT)',
          );
          await db.execute(
            'CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT)',
          );
          await db.insert('habits', {
            'id': 'old',
            'title': '旧习惯',
            'kind': 'quantity',
            'start_day': '2026-10-01',
            'target': 2000000,
            'unit': 'ml',
            'weekdays': 127,
            'icon': 1,
            'archived': 0,
          });
          await db.insert('entries', {
            'habit_id': 'old',
            'day': '2026-11-04',
            'value': 250001,
          });
        },
      ),
    );
    await old.close();
    final migrated = await AppStore.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    expect(await migrated.db.getVersion(), 5);
    expect((await migrated.entries()).single.value, 250001);
    expect(
      (await migrated.plans()).single.effectiveDay,
      Day.parse('2026-10-01'),
    );
    expect((await migrated.habits()).single.context, HabitContext.anytime);
    expect(await migrated.groups(), isEmpty);
    await migrated.close();
  });
  test(
    'target/unit/schedule edit starts tomorrow, historical values and judgment stay stable',
    () async {
      final h = base();
      await store.saveHabit(h, create: true);
      await store.setRecord('h', today, 1000, today: today);
      await store.saveHabit(
        Habit.fromMap({
          ...h.toMap(),
          'target': 5000,
          'unit': 'chapters',
          'schedule': 'interval',
          'interval_days': 2,
        }),
        today: today,
      );
      final app = controller();
      await app.load();
      expect(app.achieved(app.habits.single, today), isTrue);
      expect(app.planAt(h, today).unit, 'pages');
      expect(app.planAt(h, today.plus(1)).unit, 'chapters');
      expect(app.scheduled(h, today.plus(1)), isTrue);
      expect(app.scheduled(h, today.plus(2)), isFalse);
      expect(app.scheduled(h, today.plus(3)), isTrue);
      expect(app.pending(h)!.target, 5000);
      app.dispose();
    },
  );
  test(
    'same-day changes replace future plan and reverting removes redundant version',
    () async {
      final h = base();
      await store.saveHabit(h, create: true);
      await store.saveHabit(
        Habit.fromMap({...h.toMap(), 'target': 2000}),
        today: today,
      );
      await store.saveHabit(
        Habit.fromMap({...h.toMap(), 'target': 3000}),
        today: today,
      );
      expect((await store.plans()).length, 2);
      expect((await store.plans()).last.target, 3000);
      await store.saveHabit(h, today: today);
      expect((await store.plans()).length, 1);
      expect((await store.habits()).single.target, 1000);
    },
  );
  test(
    'weekly count counts achieved days, stops at selected day and resets at Monday',
    () async {
      final h = base(schedule: ScheduleKind.weekly);
      await store.saveHabit(h, create: true);
      for (final d in ['2026-11-01', '2026-11-02', '2026-11-04']) {
        await store.setRecord('h', Day.parse(d), 1000, today: today);
      }
      await store.setRecord('h', today, 999, today: today);
      final app = controller();
      await app.load();
      expect(app.weekCount(h, today), 2);
      expect(app.weekCount(h, Day.parse('2026-11-02')), 1);
      expect(app.weekCount(h, Day.parse('2026-11-09')), 0);
      expect(app.dailyPlanned, isEmpty);
      expect(app.weeklyPlanned.length, 1);
      await store.saveHabit(
        Habit.fromMap({...h.toMap(), 'target': 2000}),
        today: today.plus(-1),
      );
      await app.load();
      expect(
        app.weekCount(h, today),
        0,
      ); // New plan does not count the former target.
      app.dispose();
    },
  );
  test(
    'calendar intervals cross DST and year without elapsed-hour assumptions',
    () {
      final p = HabitPlan(
        habitId: 'h',
        effectiveDay: Day.parse('2026-03-07'),
        target: 1000,
        unit: '',
        schedule: ScheduleKind.interval,
        intervalDays: 2,
      );
      expect(p.scheduled(Day.parse('2026-03-09')), isTrue);
      expect(p.scheduled(Day.parse('2026-03-08')), isFalse);
      expect(Day.parse('2027-01-01').daysSince(Day.parse('2026-12-31')), 1);
      expect(() => Day.parse('2026-02-30'), throwsFormatException);
    },
  );
  test(
    'deleting group clears membership, keeps habit history; ordering validates full set',
    () async {
      await store.saveGroup(
        const HabitGroup(id: 'g', name: 'Health'),
        create: true,
      );
      final h = Habit.fromMap({
        ...base().toMap(),
        'group_id': 'g',
        'context': 'morning',
      });
      await store.saveHabit(h, create: true);
      await store.saveHabit(
        Habit.fromMap({...h.toMap(), 'id': 'second'}),
        create: true,
      );
      await store.setRecord('h', today, 1000, today: today);
      await expectLater(store.reorderHabits(['h', 'h']), throwsArgumentError);
      await store.reorderHabits(['second', 'h']);
      expect((await store.habits()).map((h) => h.id).toList(), ['second', 'h']);
      await store.removeGroup('g');
      expect((await store.habits()).every((h) => h.groupId == null), isTrue);
      expect((await store.entries()).single.value, 1000);
      final app = controller();
      await app.load();
      app.filter(context: HabitContext.evening);
      expect(app.planned, isEmpty);
      expect(app.allDailyPlanned.length, 2);
      app.dispose();
    },
  );
}
