import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/habit_break.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/achievements.dart';
import 'package:daypanel/presentation/tasks.dart';
import 'package:daypanel/presentation/statistics.dart';
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  final today = Day.parse('2026-11-08');
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => today.date);
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell(Widget child) => MaterialApp(
    theme: dayPanelTheme(Brightness.light),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  Future<void> pick(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        150,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .3);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Habit habit({
    ScheduleKind schedule = ScheduleKind.weekdays,
    HabitKind kind = HabitKind.check,
  }) => Habit(
    id: 'h',
    title: 'Reading',
    kind: kind,
    startDay: Day.parse('2026-10-01'),
    schedule: schedule,
    target: kind == HabitKind.check ? 1000 : 10000,
    unit: kind == HabitKind.check ? '' : 'pages',
  );
  List<Widget> statisticRows(WidgetTester t) =>
      (t.widget<ListView>(find.byType(ListView).first).childrenDelegate
              as SliverChildListDelegate)
          .children;
  bool row(WidgetTester t, String key) =>
      statisticRows(t).any((w) => w.key == Key(key));

  testWidgets(
    'daily reward prompt is absent for empty weekly-only and all-rest days',
    (t) async {
      Widget panel() => shell(
        Scaffold(
          body: DailyCardPanel(app: app, day: today),
        ),
      );
      await t.pumpWidget(panel());
      await t.pumpAndSettle();
      expect(find.text("Today's card"), findsNothing);
      await store.saveHabit(habit(schedule: ScheduleKind.weekly), create: true);
      await app.load();
      await t.pumpWidget(panel());
      await t.pumpAndSettle();
      expect(find.text("Today's card"), findsNothing);
      await store.saveHabit(habit(), today: today.plus(-1));
      await store.addBreak(
        HabitBreak(
          id: 'rest',
          habitId: 'h',
          start: today,
          kind: BreakKind.pause,
        ),
        today: today,
      );
      await app.load();
      await t.pumpWidget(panel());
      await t.pumpAndSettle();
      expect(find.text("Today's card"), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('saved card remains available when obligations later all rest', (
    t,
  ) async {
    await store.saveHabit(habit(), create: true);
    await store.setRecord('h', today, 1000, today: today);
    await store.addBreak(
      HabitBreak(id: 'rest', habitId: 'h', start: today, kind: BreakKind.pause),
      today: today,
    );
    await app.load();
    await t.pumpWidget(
      shell(
        Scaffold(
          body: DailyCardPanel(app: app, day: today),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('View card'), findsOneWidget);
    expect(app.cards, hasLength(1));
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'weekly-only statistics do not show unrelated daily completion metrics',
    (t) async {
      await store.saveHabit(habit(schedule: ScheduleKind.weekly), create: true);
      await app.load();
      await t.pumpWidget(
        shell(StatisticsPage(app: app, habitId: 'h', initialTab: 1)),
      );
      await t.pumpAndSettle();
      expect(row(t, 'weekly-statistics'), isTrue);
      expect(row(t, 'daily-statistics'), isFalse);
      expect(find.textContaining('Archive history is tracked'), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'mixed historical plans show both metrics only while each is in range',
    (t) async {
      await store.saveHabit(habit(), create: true);
      await store.saveHabit(
        habit(schedule: ScheduleKind.weekly),
        today: Day.parse('2026-10-24'),
      );
      await app.load();
      await t.pumpWidget(
        shell(StatisticsPage(app: app, habitId: 'h', initialTab: 1)),
      );
      await t.pumpAndSettle();
      expect(row(t, 'daily-statistics'), isTrue);
      expect(row(t, 'weekly-statistics'), isTrue);
      await pick(t, find.byKey(const Key('statistics-range-7')));
      expect(row(t, 'daily-statistics'), isFalse);
      expect(row(t, 'weekly-statistics'), isTrue);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'quantity history is first and keeps daily attainment as secondary',
    (t) async {
      await store.saveHabit(habit(kind: HabitKind.quantity), create: true);
      await store.setRecord('h', today, 5000, today: today);
      await app.load();
      await t.pumpWidget(
        shell(StatisticsPage(app: app, habitId: 'h', initialTab: 1)),
      );
      await t.pumpAndSettle();
      final children = statisticRows(t);
      expect(
        children.indexWhere((w) => w.key == const Key('quantity-statistics')),
        lessThan(
          children.indexWhere((w) => w.key == const Key('daily-statistics')),
        ),
      );
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('one-time title opens details without entering an editor', (
    t,
  ) async {
    await store.saveTask(
      const SmallTask(id: 'task', title: 'Post a parcel'),
      create: true,
    );
    await app.load();
    await t.pumpWidget(shell(Scaffold(body: TasksPage(app: app))));
    await t.pumpAndSettle();
    await pick(t, find.text('Post a parcel'));
    expect(find.byType(OneTimeTaskPage), findsOneWidget);
    expect(find.byType(EntryEditor), findsNothing);
    await pick(t, find.byKey(const Key('one-time-record')));
    expect((await store.tasks()).single.completedDay, today);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'resident opens today, history secondary; passed date remains the write target',
    (t) async {
      final yesterday = today.plus(-1);
      await store.saveTask(
        SmallTask(
          id: 'r',
          title: 'Tidy up',
          resident: true,
          startDay: yesterday,
        ),
        create: true,
        today: yesterday,
      );
      await app.load();
      await t.pumpWidget(shell(ResidentTaskPage(app: app, id: 'r')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const Key('resident-record')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(const Key('resident-history-date')), findsNothing);
      expect(find.text('Archive'), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(
        shell(ResidentTaskPage(app: app, id: 'r', initialDay: yesterday)),
      );
      await t.pumpAndSettle();
      await pick(t, find.byKey(const Key('resident-record')));
      expect((await store.taskEntries()).single.day, yesterday);
      expect(app.taskDoneOn(app.tasks.single, today), isFalse);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'restored resident page disables mutation and explains changed context',
    (t) async {
      await store.saveTask(
        SmallTask(id: 'r', title: 'Tidy up', resident: true, startDay: today),
        create: true,
      );
      await app.load();
      await t.pumpWidget(shell(ResidentTaskPage(app: app, id: 'r')));
      await t.pumpAndSettle();
      await app.run(
        () async => store.restoreSnapshot(await store.exportSnapshot()),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('resident-record')), findsNothing);
      expect(
        find.text(
          AppLocalizations.of(t.element(find.byType(Scaffold))).contextChanged,
        ),
        findsOneWidget,
      );
      expect(await store.taskEntries(), isEmpty);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'restored one-time page and deleted task have explicit safe empty states',
    (t) async {
      await store.saveTask(
        const SmallTask(id: 't', title: 'Post'),
        create: true,
      );
      await app.load();
      await t.pumpWidget(shell(OneTimeTaskPage(app: app, id: 't')));
      await t.pumpAndSettle();
      await app.run(
        () async => store.restoreSnapshot(await store.exportSnapshot()),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('one-time-record')), findsNothing);
      expect((await store.tasks()).single.done, isFalse);
      await t.pumpWidget(const SizedBox());
      await store.remove('tasks', 't');
      await app.load();
      await t.pumpWidget(shell(OneTimeTaskPage(app: app, id: 't')));
      await t.pumpAndSettle();
      expect(
        find.text(
          AppLocalizations.of(
            t.element(find.byType(Scaffold)),
          ).pmTaskUnavailable,
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('one-time-record')), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
}
