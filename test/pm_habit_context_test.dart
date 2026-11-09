import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/habit_break.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/habits.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => DateTime(2026, 11, 8));
    await store.saveHabit(
      Habit(
        id: 'water',
        title: 'Water',
        kind: HabitKind.quantity,
        startDay: app.today.plus(-2),
        target: 1000000,
        unit: 'ml',
        icon: 1,
      ),
      create: true,
    );
    await store.saveHabit(
      Habit.fromMap({
        ...((await store.habits()).single.toMap()),
        'target': 2000000,
      }),
      today: app.today.plus(-1),
    );
    await store.setRecord(
      'water',
      app.today.plus(-1),
      250000,
      today: app.today,
    );
    await store.setRecord('water', app.today, 500000, today: app.today);
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

  testWidgets(
    'selected historical date reaches detail and quantity instead of today',
    (t) async {
      final h = app.habits.single;
      final yesterday = app.today.plus(-1);
      await t.pumpWidget(
        shell(
          Scaffold(
            body: HabitTile(app: app, habit: h, day: yesterday),
          ),
        ),
      );
      await t.pumpAndSettle();
      await tap(t, find.text('Water'));
      expect(find.byType(HabitDetails), findsOneWidget);
      expect(find.textContaining('Saturday, November 7'), findsOneWidget);
      await tap(t, find.byKey(const Key('habit-detail-action-water')));
      expect(
        t
            .widget<TextField>(find.byKey(const Key('quantity-input')))
            .controller!
            .text,
        '250',
      );
      expect(find.textContaining('1000 ml'), findsWidgets);
      await t.enterText(find.byKey(const Key('quantity-input')), '300');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('quantity-save')));
      expect(app.value(h, yesterday), 300000);
      expect(app.value(h, app.today), 500000);
    },
  );
  testWidgets(
    'record overview does not expose management or empty journal modules',
    (t) async {
      await t.pumpWidget(shell(HabitDetails(app: app, id: 'water')));
      await t.pumpAndSettle();
      for (final label in [
        'Archive',
        'Delete',
        'Plan history',
        'Habit journal',
        'Pause from today',
        'Habit reminder',
      ]) {
        expect(find.text(label), findsNothing);
      }
      await tap(t, find.byKey(const Key('habit-settings')));
      expect(find.byType(HabitManagementPage), findsOneWidget);
      expect(find.text('Habit reminder'), findsOneWidget);
      expect(find.byKey(const Key('add-habit-note')), findsNothing);
      await tap(t, find.text('Habit journal'));
      expect(find.byKey(const Key('add-habit-note')), findsOneWidget);
    },
  );
  testWidgets(
    'history is optional and selecting a day returns to that record',
    (t) async {
      await t.pumpWidget(shell(HabitDetails(app: app, id: 'water')));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('habit-record-history')));
      await tap(t, find.byKey(Key('habit-history-${app.today.plus(-1).key}')));
      expect(find.textContaining('Saturday, November 7'), findsOneWidget);
      expect(find.byKey(const Key('back-to-record')), findsNothing);
      expect(find.textContaining('250', findRichText: true), findsWidgets);
    },
  );
  testWidgets('restore makes both old record and settings pages read only', (
    t,
  ) async {
    await t.pumpWidget(shell(HabitDetails(app: app, id: 'water')));
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('habit-settings')));
    final snap = await store.exportSnapshot();
    await app.run(() => store.restoreSnapshot(snap));
    await t.pumpAndSettle();
    expect(find.text('Data has changed'), findsOneWidget);
    expect(find.byKey(const Key('edit-habit-settings')), findsNothing);
    await tap(t, find.text('Back'));
    expect(find.text('Data has changed'), findsOneWidget);
    expect(find.byKey(const Key('habit-detail-action-water')), findsNothing);
  });
  testWidgets('deleted habit displays an explanation instead of a blank page', (
    t,
  ) async {
    await t.pumpWidget(shell(HabitDetails(app: app, id: 'water')));
    await t.pumpAndSettle();
    await app.run(() => store.remove('habits', 'water'));
    await t.pumpAndSettle();
    expect(find.text('This habit is no longer available'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });
  testWidgets(
    'non-scheduled day offers no meaningless skip, weekly skip explains the week',
    (t) async {
      await store.saveHabit(
        Habit(
          id: 'off',
          title: 'Monday walk',
          kind: HabitKind.check,
          startDay: app.today.plus(-7),
          weekdays: 1,
        ),
        create: true,
      );
      await app.load();
      await t.pumpWidget(shell(HabitDetails(app: app, id: 'off')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('skip-record-day')), findsNothing);
      await t.pumpWidget(const SizedBox());
      await store.saveHabit(
        Habit(
          id: 'weekly',
          title: 'Weekly run',
          kind: HabitKind.check,
          startDay: app.today.plus(-7),
          schedule: ScheduleKind.weekly,
          weeklyGoal: 2,
        ),
        create: true,
      );
      await app.load();
      await t.pumpWidget(shell(HabitDetails(app: app, id: 'weekly')));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('skip-record-day')));
      expect(
        find.textContaining('excluded from full-week goal assessment'),
        findsOneWidget,
      );
      await tap(t, find.text('Cancel'));
      expect(await store.breaks(), isEmpty);
    },
  );
  testWidgets(
    'archived skip and historical vacation expose no current rest-management action',
    (t) async {
      final start = app.today.plus(-2);
      await store.saveHabit(
        Habit(
          id: 'skip',
          title: 'Skipped habit',
          kind: HabitKind.check,
          startDay: start,
        ),
        create: true,
      );
      await store.addBreak(
        HabitBreak(
          id: 'skip-day',
          habitId: 'skip',
          start: start,
          end: start,
          kind: BreakKind.skip,
        ),
        today: app.today,
      );
      await store.setArchived('skip', true, today: app.today);
      await app.load();
      await t.pumpWidget(
        shell(HabitDetails(app: app, id: 'skip', initialDay: start)),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('skip-record-day')), findsNothing);
      expect(find.byKey(const Key('readonly-habit-record')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await store.addBreak(
        HabitBreak(
          id: 'vacation',
          habitId: 'water',
          start: app.today,
          end: app.today.plus(2),
          kind: BreakKind.vacation,
        ),
        today: app.today,
      );
      await app.load();
      await t.pumpWidget(shell(HabitDetails(app: app, id: 'water')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('habit-detail-action-water')), findsNothing);
      expect(find.text('Resume today'), findsNothing);
      expect(find.text('Rest days'), findsNothing);
      expect(find.textContaining('500'), findsOneWidget);
    },
  );
  testWidgets('archived explicit zero is not confused with a missing record', (
    t,
  ) async {
    await store.saveHabit(
      Habit(
        id: 'zero',
        title: 'A check',
        kind: HabitKind.check,
        startDay: app.today,
      ),
      create: true,
    );
    await store.setRecord('zero', app.today, 0, today: app.today);
    await store.setArchived('zero', true, today: app.today);
    await app.load();
    await t.pumpWidget(shell(HabitDetails(app: app, id: 'zero')));
    await t.pumpAndSettle();
    expect(find.text('Not completed'), findsOneWidget);
    expect(find.text('Not logged'), findsNothing);
    expect(
      (await store.entries()).where((e) => e.habitId == 'zero').single.value,
      0,
    );
  });
  for (final lang in ['en', 'zh']) {
    testWidgets('$lang narrow enlarged record and settings remain usable', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 800);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(
        shell(
          HabitDetails(app: app, id: 'water'),
          language: lang,
          dark: true,
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await tap(t, find.byKey(const Key('habit-settings')));
      expect(t.takeException(), isNull);
      expect(
        find.byKey(const Key('edit-habit-settings')).hitTestable(),
        findsOneWidget,
      );
    });
  }
}
