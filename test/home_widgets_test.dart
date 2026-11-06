import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/widget_platform.dart';
import 'package:daypanel/domain/models.dart';
import 'achievements_test.dart' show FakeFeedback;
import 'reminders_test.dart' show FakeReminderPlatform;

class FakeWidgets implements WidgetPlatform {
  int refreshes = 0, closes = 0, opens = 0;
  bool valid = true, fail = false;
  final configs = <(int, String, int)>[];
  @override
  Future<void> refresh() async {
    refreshes++;
    if (fail) throw StateError('Unavailable');
  }

  @override
  Future<Map<String, Object?>?> launch() async => null;
  @override
  Future<bool> validate(Map<String, Object?> request) async => valid;
  @override
  Future<void> configure(int widgetId, String id, int generation) async {
    configs.add((widgetId, id, generation));
  }

  @override
  Future<void> close() async {
    closes++;
  }

  @override
  Future<void> openApp() async {
    opens++;
  }
}

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late FakeWidgets widgets;
  late FakeReminderPlatform reminders;
  late FakeFeedback feedback;
  var now = DateTime(2026, 11, 6);
  final day = Day(now);
  Habit habit(
    String id, {
    HabitKind kind = HabitKind.check,
    ScheduleKind schedule = ScheduleKind.weekdays,
  }) => Habit(
    id: id,
    title: id,
    kind: kind,
    startDay: day,
    schedule: schedule,
    target: kind == HabitKind.quantity ? 2000000 : 1000,
    unit: kind == HabitKind.quantity ? 'ml' : '',
  );
  setUp(() async {
    now = DateTime(2026, 11, 6);
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    widgets = FakeWidgets();
    reminders = FakeReminderPlatform();
    feedback = FakeFeedback();
    app = AppController(
      store,
      clock: () => now,
      widgetPlatform: widgets,
      reminderPlatform: reminders,
      completionFeedback: feedback,
    );
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Future<bool> complete(
    String id, {
    String kind = 'habit',
    int epoch = 0,
    Day? date,
  }) =>
      app.recordFromWidget(kind: kind, id: id, day: date ?? day, epoch: epoch);

  test(
    'duplicate widget completion is explicit, earns one card, feedback once and refreshes',
    () async {
      await store.saveHabit(habit('read'), create: true);
      await store.preference('completion_sound', 'on');
      await app.load();
      expect(await complete('read'), isTrue);
      expect(await complete('read'), isTrue);
      expect((await store.entries()).single.value, 1000);
      expect((await store.cards()).length, 1);
      expect(feedback.calls.length, 1);
      expect(widgets.refreshes, 2);
    },
  );
  test(
    'quantity cannot be completed blindly, saves explicit total and uses current plan',
    () async {
      final h = habit('water', kind: HabitKind.quantity);
      await store.saveHabit(h, create: true);
      await app.load();
      expect(await complete('water'), isFalse);
      expect(await store.entries(), isEmpty);
      expect(
        await app.recordHabit(h, day, 250001, 0, requireToday: true),
        isTrue,
      );
      expect(
        await app.recordHabit(h, day, 250001, 0, requireToday: true),
        isTrue,
      );
      expect((await store.entries()).single.value, 250001);
      expect(await store.cards(), isEmpty);
    },
  );
  test(
    'resident duplicate is one row; next day blank is not a new task',
    () async {
      await store.saveTask(
        SmallTask(id: 't', title: 'Stretch', resident: true, startDay: day),
        create: true,
        today: day,
      );
      await app.load();
      expect(await complete('t', kind: 'task'), isTrue);
      expect(await complete('t', kind: 'task'), isTrue);
      expect((await store.taskEntries()).length, 1);
      now = now.add(const Duration(days: 1));
      expect(await complete('t', kind: 'task'), isFalse);
      expect(await complete('t', kind: 'task', date: app.today), isTrue);
      expect((await store.tasks()).length, 1);
      expect((await store.taskEntries()).length, 2);
    },
  );
  test(
    'one-time repeated completion keeps original date and preserves due date',
    () async {
      await store.saveTask(
        SmallTask(id: 't', title: 'Post', dueDay: day.plus(-2)),
        create: true,
      );
      await app.load();
      expect(await complete('t', kind: 'task'), isTrue);
      now = now.add(const Duration(days: 1));
      expect(await complete('t', kind: 'task', date: app.today), isTrue);
      final t = (await store.tasks()).single;
      expect(t.completedDay, day);
      expect(t.dueDay, day.plus(-2));
    },
  );
  test('stale day, archived and missing widget objects cannot write', () async {
    await store.saveHabit(habit('h'), create: true);
    await app.load();
    expect(await complete('h', date: day.plus(-1)), isFalse);
    await store.setArchived('h', true, today: day);
    await app.load();
    expect(await complete('h'), isFalse);
    await store.remove('habits', 'h');
    await app.load();
    expect(await complete('h'), isFalse);
    expect(await store.entries(), isEmpty);
  });
  test(
    'restore and rollback invalidate old widget generation, backup stays schema7',
    () async {
      await store.saveHabit(habit('h'), create: true);
      await app.load();
      final backup = await store.exportSnapshot();
      await app.run(() => store.restoreSnapshot(backup));
      expect(await complete('h'), isFalse);
      expect(await store.entries(), isEmpty);
      expect(await complete('h', epoch: app.generation), isTrue);
      final recovery = await store.recoverySnapshot();
      await app.run(() => store.restoreSnapshot(recovery!, rollback: true));
      expect(await complete('h', epoch: 1), isFalse);
      expect(
        (await store.exportSnapshot()).tables.keys.any(
          (k) => k.contains('widget'),
        ),
        isFalse,
      );
    },
  );
  test('weekly-only completion does not award daily card', () async {
    await store.saveHabit(
      habit('w', schedule: ScheduleKind.weekly),
      create: true,
    );
    await app.load();
    expect(await complete('w'), isTrue);
    expect(await store.cards(), isEmpty);
  });
  test('refresh failure does not roll back successful record', () async {
    await store.saveHabit(habit('h'), create: true);
    await app.load();
    widgets.fail = true;
    expect(await complete('h'), isTrue);
    expect(app.widgetSyncFailed, isTrue);
    expect((await store.entries()).single.value, 1000);
  });
  test(
    'transaction generation rejects another Activity stale writer and nested failure rolls back',
    () async {
      final dir = await Directory.systemTemp.createTemp('widget-generation-');
      final a = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/db',
      );
      final b = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/db',
      );
      try {
        await a.saveHabit(habit('h'), create: true);
        final snap = await a.exportSnapshot();
        await b.restoreSnapshot(snap);
        await expectLater(
          a.inGeneration(0, () => a.setRecord('h', day, 1000, today: day)),
          throwsStateError,
        );
        expect(await a.entries(), isEmpty);
        await expectLater(
          a.inGeneration(1, () async {
            await a.setRecord('h', day, 1000, today: day);
            throw StateError('interrupted operation');
          }),
          throwsStateError,
        );
        expect(await b.entries(), isEmpty);
        expect(await b.cards(), isEmpty);
      } finally {
        await a.close();
        await b.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
