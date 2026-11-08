import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/habit_templates.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/editors.dart';
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
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell(Widget child, {String locale = 'en', double scale = 1}) =>
      MaterialApp(
        locale: Locale(locale),
        theme: dayPanelTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      );
  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        180,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .35);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> openCreate(WidgetTester t) async {
    await t.pumpWidget(
      shell(
        Builder(
          builder: (c) => TextButton(
            onPressed: () => openEditor(c, app, 'habit'),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
  }

  Future<Habit> fixture({
    HabitKind kind = HabitKind.quantity,
    int target = 20000,
    String unit = 'pages',
    int value = 10000,
  }) async {
    final h = Habit(
      id: 'h',
      title: 'Practice',
      kind: kind,
      startDay: app.today.plus(-5),
      target: target,
      unit: unit,
    );
    await store.saveHabit(h, create: true, today: app.today);
    await store.setRecord(h.id, app.today, value, today: app.today);
    await app.load();
    return app.habits.single;
  }

  Future<void> openRecord(WidgetTester t, Habit h) async {
    await t.pumpWidget(
      shell(
        Builder(
          builder: (c) => TextButton(
            onPressed: () => openQuantity(c, app, h, app.today),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
  }

  Future<void> input(WidgetTester t, String text) async {
    await t.enterText(find.byKey(const Key('quantity-input')), text);
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
  }

  test(
    'integer suggestions and editable template schedules have explicit semantics',
    () {
      expect(quantitySuggestions(3000, '次', wholeCounts: true), [
        1000,
        2000,
        3000,
      ]);
      expect(quantitySuggestions(1000, 'times', wholeCounts: true), [1000]);
      expect(quantitySuggestions(2500, 'km'), [1000, 2500]);
      expect(
        habitTemplates.where((t) => t.chooseSchedule).map((t) => t.id).toSet(),
        {'running', 'cycling', 'plant', 'strength'},
      );
      expect(habitTemplates.length, 16);
    },
  );

  testWidgets(
    'new count keeps searched title and opens visible today detail without clearing context',
    (t) async {
      final priorDay = app.today.plus(-1);
      app.select(priorDay);
      app.filter(context: HabitContext.morning);
      await openCreate(t);
      await t.enterText(
        find.byKey(const Key('template-search')),
        'Practice scales',
      );
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('custom-habit')));
      expect(
        t
            .widget<TextFormField>(find.byKey(const Key('entry-title')))
            .controller!
            .text,
        'Practice scales',
      );
      await tap(t, find.byKey(const Key('habit-kind-count')));
      await t.enterText(find.byKey(const Key('habit-target')), '1.5');
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(t, find.byKey(const Key('save-entry')));
      expect(await store.habits(), isEmpty);
      await t.enterText(find.byKey(const Key('habit-target')), '3');
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(t, find.byKey(const Key('save-entry')));
      expect(find.byType(HabitDetails), findsOneWidget);
      expect((await store.habits()).single.kind, HabitKind.count);
      expect((await store.habits()).single.target, 3000);
      expect(await store.entries(), isEmpty);
      expect(app.selectedDay, priorDay);
      expect(app.contextFilter, HabitContext.morning);
      expect(
        t.widget<HabitDetails>(find.byType(HabitDetails)).initialDay,
        app.today,
      );
    },
  );

  testWidgets('uncertain template must choose schedule before saving', (
    t,
  ) async {
    await openCreate(t);
    await tap(t, find.byKey(const Key('template-plant')));
    await tap(t, find.byKey(const Key('save-entry')));
    expect(await store.habits(), isEmpty);
    await tap(t, find.byKey(const Key('habit-schedule-weekly')));
    await t.enterText(find.byKey(const Key('schedule-number')), '2');
    FocusManager.instance.primaryFocus?.unfocus();
    await tap(t, find.byKey(const Key('save-entry')));
    expect((await store.habits()).single.schedule, ScheduleKind.weekly);
    expect((await store.habits()).single.weeklyGoal, 2);
  });

  testWidgets(
    'add amount previews explicit resulting total and saves only on confirmation',
    (t) async {
      final h = await fixture();
      await openRecord(t, h);
      await tap(t, find.byKey(const Key('quantity-mode-add')));
      await input(t, '5');
      expect((await store.entries()).single.value, 10000);
      final preview = t
          .widget<Text>(find.byKey(const Key('quantity-replace-preview')))
          .data!;
      expect(preview, contains('15 pages'));
      await tap(t, find.byKey(const Key('quantity-save')));
      expect((await store.entries()).single.value, 15000);
    },
  );

  testWidgets('cancelling a drafted addition preserves the prior quantity', (
    t,
  ) async {
    final h = await fixture(unit: 'km', target: 5000, value: 2500);
    await openRecord(t, h);
    await tap(t, find.byKey(const Key('quantity-mode-add')));
    await input(t, '1.25');
    await tap(t, find.text('Cancel').last);
    expect((await store.entries()).single.value, 2500);
  });

  testWidgets(
    'count rejects fractions and accepts an explicit added repetition',
    (t) async {
      final h = await fixture(
        kind: HabitKind.count,
        unit: 'times',
        target: 3000,
        value: 1000,
      );
      await openRecord(t, h);
      expect(find.text('0.75 times'), findsNothing);
      expect(find.text('1.5 times'), findsNothing);
      await input(t, '1.5');
      await tap(t, find.byKey(const Key('quantity-save')));
      expect((await store.entries()).single.value, 1000);
      await tap(t, find.byKey(const Key('quantity-mode-add')));
      await tap(t, find.byKey(const Key('quantity-save')));
      expect((await store.entries()).single.value, 2000);
    },
  );

  testWidgets(
    'ABA after opening numeric form is rejected and reload is deliberate',
    (t) async {
      final h = await fixture(
        kind: HabitKind.count,
        unit: 'times',
        target: 3000,
        value: 1000,
      );
      await openRecord(t, h);
      await tap(t, find.byKey(const Key('quantity-mode-add')));
      await store.setRecord(h.id, app.today, 2000, today: app.today);
      await store.setRecord(h.id, app.today, 1000, today: app.today);
      await tap(t, find.byKey(const Key('quantity-save')));
      expect((await store.entries()).single.value, 1000);
      expect(find.byKey(const Key('quantity-reload')), findsOneWidget);
      await tap(t, find.byKey(const Key('quantity-reload')));
      expect(
        t
            .widget<TextField>(find.byKey(const Key('quantity-input')))
            .controller!
            .text,
        '1',
      );
      await tap(t, find.byKey(const Key('quantity-mode-add')));
      await tap(t, find.byKey(const Key('quantity-save')));
      expect((await store.entries()).single.value, 2000);
    },
  );

  for (final locale in ['en', 'zh']) {
    testWidgets(
      '$locale three record modes remain usable at 320dp and 160 percent',
      (t) async {
        t.view.physicalSize = const Size(320, 740);
        t.view.devicePixelRatio = 1;
        addTearDown(() {
          t.view.resetPhysicalSize();
          t.view.resetDevicePixelRatio();
        });
        await t.pumpWidget(
          shell(
            EntryEditor(app: app, type: 'habit'),
            locale: locale,
            scale: 1.6,
          ),
        );
        await t.pumpAndSettle();
        await tap(t, find.byKey(const Key('habit-kind-count')));
        expect(find.byKey(const Key('habit-target')), findsOneWidget);
        await tap(t, find.byKey(const Key('habit-schedule-weekly')));
        await tap(t, find.byKey(const Key('habit-rule-preview')));
        expect(t.takeException(), isNull);
      },
    );
  }
}
