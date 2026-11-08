import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/journal.dart';
import 'package:daypanel/domain/habit_break.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/achievements.dart';
import 'package:daypanel/presentation/journal.dart';
import 'package:daypanel/presentation/review.dart';
import 'package:daypanel/presentation/statistics.dart';
import 'package:daypanel/presentation/tasks.dart';
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
  Widget shell(Widget child, {String language = 'en', bool dark = false}) =>
      MaterialApp(
        locale: Locale(language),
        theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );
  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        180,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .4);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Habit habit({
    String id = 'h',
    ScheduleKind schedule = ScheduleKind.weekdays,
    HabitKind kind = HabitKind.check,
  }) => Habit(
    id: id,
    title: 'Practice',
    kind: kind,
    startDay: Day.parse('2026-09-01'),
    target: kind == HabitKind.check ? 1000 : 3000,
    unit: kind == HabitKind.count
        ? 'times'
        : kind == HabitKind.quantity
        ? 'km'
        : '',
    schedule: schedule,
  );

  testWidgets(
    'empty month search expands range without dropping text or habit',
    (t) async {
      await store.saveHabit(habit(), create: true);
      await store.saveNote(
        Note(
          id: 'old',
          body: 'A quiet reading day',
          day: Day.parse('2026-10-02'),
          habitId: 'h',
        ),
        create: true,
        today: today,
      );
      await store.saveNote(
        Note(
          id: 'other',
          body: 'A quiet independent day',
          day: Day.parse('2026-10-03'),
        ),
        create: true,
        today: today,
      );
      await app.load();
      app.filterNotes(JournalQuery(month: today, habitId: 'h', text: 'quiet'));
      await t.pumpWidget(shell(Scaffold(body: JournalPage(app: app))));
      await t.pumpAndSettle();
      expect(app.visibleNotes, isEmpty);
      expect(find.text('Search in November 2026'), findsOneWidget);
      await tap(t, find.text('Search all months'));
      expect(app.journalQuery.text, 'quiet');
      expect(app.journalQuery.habitId, 'h');
      expect(app.journalQuery.month, isNull);
      expect(app.visibleNotes.map((n) => n.id), ['old']);
      expect(find.text('A quiet reading day'), findsOneWidget);
      expect(find.text('Search in All months'), findsOneWidget);
    },
  );

  testWidgets(
    'review day opens that day with habits tasks and notes and no writes',
    (t) async {
      final day = today.plus(-2);
      await store.saveHabit(habit(), create: true);
      await store.setRecord('h', day, 1000, today: today);
      await store.saveTask(
        SmallTask(id: 'task', title: 'Return the book'),
        create: true,
        today: today,
      );
      await store.completeTask('task', true, day);
      await store.saveNote(
        Note(id: 'note', body: 'A calm afternoon', day: day),
        create: true,
        today: today,
      );
      await app.load();
      final before = (await store.exportSnapshot()).tables;
      await t.pumpWidget(shell(ReviewPage(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.byKey(Key('review-day-${day.key}')));
      expect(t.widget<DayHistoryPage>(find.byType(DayHistoryPage)).day, day);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Return the book'), findsOneWidget);
      expect(find.text('A calm afternoon'), findsOneWidget);
      expect((await store.entries()).single.day, day);
      expect((await store.notes()).single.body, 'A calm afternoon');
      expect((await store.exportSnapshot()).tables, before);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.byType(ReviewPage), findsOneWidget);
    },
  );

  testWidgets(
    'review empty has explanatory state and still allows day inspection',
    (t) async {
      await t.pumpWidget(shell(ReviewPage(app: app)));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('review-empty')), findsOneWidget);
      await tap(t, find.byKey(Key('review-day-${today.key}')));
      expect(find.byType(DayHistoryPage), findsOneWidget);
      expect(await store.entries(), isEmpty);
    },
  );

  testWidgets(
    'historical numeric summary ends on selected day and latest is explicit',
    (t) async {
      final selected = Day.parse('2026-10-09');
      await store.saveHabit(habit(kind: HabitKind.count), create: true);
      await store.setRecord('h', selected, 2000, today: today);
      await store.setRecord('h', today, 3000, today: today);
      await app.load();
      await t.pumpWidget(
        shell(
          StatisticsPage(
            app: app,
            habitId: 'h',
            initialTab: 1,
            initialDay: selected,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('2026-09-10 — 2026-10-09'), findsOneWidget);
      final rows =
          (t.widget<ListView>(find.byType(ListView).first).childrenDelegate
                  as SliverChildListDelegate)
              .children;
      expect(
        rows.any((w) => w.key == const Key('quantity-statistics')),
        isTrue,
      );
      await tap(t, find.byKey(const Key('statistics-latest')));
      expect(find.text('2026-10-10 — 2026-11-08'), findsOneWidget);
      expect(await store.entries(), hasLength(2));
    },
  );

  testWidgets(
    'statistics table calendar and timeline start at historical date',
    (t) async {
      final selected = Day.parse('2025-10-09');
      await t.pumpWidget(shell(StatisticsPage(app: app, initialDay: selected)));
      await t.pumpAndSettle();
      expect(find.text('2025-10-06 — 2025-10-12'), findsOneWidget);
      await tap(t, find.byKey(const Key('statistics-tab-2')));
      expect(find.text('2025'), findsOneWidget);
      await tap(t, find.byKey(const Key('statistics-tab-3')));
      expect(find.text('October 2025'), findsOneWidget);
      expect(find.textContaining('2025-10-09'), findsOneWidget);
    },
  );

  testWidgets(
    'resident action appears before ten future tasks and remains once per day',
    (t) async {
      await store.saveTask(
        SmallTask(
          id: 'resident',
          title: 'Care for plants',
          resident: true,
          startDay: today,
        ),
        create: true,
        today: today,
      );
      for (var i = 0; i < 10; i++) {
        await store.saveTask(
          SmallTask(
            id: 'future$i',
            title: 'Future $i',
            dueDay: today.plus(i + 1),
          ),
          create: true,
          today: today,
        );
      }
      await app.load();
      await t.pumpWidget(
        shell(
          Scaffold(
            body: ListenableBuilder(
              listenable: app,
              builder: (_, _) => TasksPage(app: app),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Care for plants').hitTestable(), findsOneWidget);
      expect(t.getTopLeft(find.text('Care for plants')).dy, lessThan(300));
      expect(app.oneTimeTasks, hasLength(10));
      final record = find.byKey(const Key('task-action-resident'));
      await tap(t, record);
      expect(
        app.taskEntries.where((e) => e.taskId == 'resident'),
        hasLength(1),
      );
      await store.setResidentRecord('resident', today, true, today: today);
      expect(await store.taskEntries(), hasLength(1));
    },
  );

  testWidgets(
    'card empty state distinguishes no daily goal and resting from eligible day',
    (t) async {
      Future<void> showCards() async {
        await app.load();
        await t.pumpWidget(shell(CardCollection(app: app)));
        await t.pumpAndSettle();
      }

      await showCards();
      expect(find.textContaining('There are no daily habits'), findsOneWidget);
      await store.saveHabit(habit(schedule: ScheduleKind.weekly), create: true);
      await showCards();
      expect(find.textContaining('There are no daily habits'), findsOneWidget);
      await store.saveHabit(habit(), today: today.plus(-1));
      await showCards();
      expect(find.textContaining('There are no daily habits'), findsNothing);
      await store.addBreak(
        HabitBreak(
          id: 'rest',
          habitId: 'h',
          start: today,
          kind: BreakKind.pause,
        ),
        today: today,
      );
      await showCards();
      expect(find.textContaining('There are no daily habits'), findsOneWidget);
    },
  );

  for (final language in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$language $dark historical stats and search fit 320dp at 160 percent',
        (t) async {
          t.view.physicalSize = const Size(320, 720);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          Widget scaled(Widget child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(1.6),
            ),
            child: child,
          );
          await store.saveHabit(habit(kind: HabitKind.count), create: true);
          await app.load();
          app.filterNotes(JournalQuery(month: today, text: 'missing'));
          for (final page in [
            Scaffold(body: JournalPage(app: app)),
            StatisticsPage(
              app: app,
              initialDay: today.plus(-30),
              initialTab: 1,
              habitId: 'h',
            ),
            ReviewPage(app: app),
            CardCollection(app: app),
          ]) {
            await t.pumpWidget(
              shell(scaled(page), language: language, dark: dark),
            );
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
          }
        },
      );
    }
  }
}
