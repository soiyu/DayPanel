import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/habit_templates.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/habit_catalog.dart';
import 'package:daypanel/presentation/habit_icon.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  test(
    'unit-aware totals use everyday amounts, exact integers and the historical target',
    () {
      expect(quantitySuggestions(1500000, '毫升'), [
        250000,
        500000,
        1000000,
        1500000,
      ]);
      expect(quantitySuggestions(10000, 'pages'), [1000, 5000, 10000]);
      expect(quantitySuggestions(1000, 'ml'), [1000]);
      expect(quantitySuggestions(1, 'custom'), [1]);
      expect(quantitySuggestions(10000, 'min'), [5000, 10000]);
      expect(quantitySuggestions(3000, 'km'), [1000, 3000]);
    },
  );
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => DateTime(2026, 11, 7));
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell({String language = 'en', bool dark = false, Widget? child}) =>
      MaterialApp(
        theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home:
            child ??
            Builder(
              builder: (c) => Scaffold(
                body: TextButton(
                  onPressed: () => openEditor(c, app, 'habit'),
                  child: const Text('Open'),
                ),
              ),
            ),
      );
  Future<void> open(WidgetTester t) async {
    await t.pumpWidget(shell());
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
  }

  Future<void> pick(WidgetTester t, Key key) async {
    final f = find.byKey(key);
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .4);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  test(
    'specific semantics match both languages without incidental English substrings',
    () {
      expect(suggestedHabitIcon('每天喝水'), 1);
      expect(suggestedHabitIcon('Read a page'), 2);
      expect(suggestedHabitIcon('Water plants'), 11);
      expect(suggestedHabitIcon('start tomorrow'), isNull);
      expect(suggestedHabitIcon('一起散步'), 3);
      expect(suggestedHabitIcon('coffee'), 19);
      expect(
        habitTemplates.map((t) => t.id).toSet().length,
        habitTemplates.length,
      );
    },
  );
  testWidgets(
    'water template has real units and quantity; cancelling creates nothing',
    (t) async {
      await open(t);
      expect(await store.habits(), isEmpty);
      await pick(t, const Key('template-water'));
      expect(
        t
            .widget<TextFormField>(find.byKey(const Key('habit-target')))
            .controller!
            .text,
        '1500',
      );
      expect(
        t
            .widget<TextFormField>(find.byKey(const Key('habit-unit')))
            .controller!
            .text,
        'ml',
      );
      await t.tap(find.text('Cancel').last);
      await t.pumpAndSettle();
      expect(await store.habits(), isEmpty);
    },
  );
  testWidgets(
    'template can be edited and persists ordinary plans without records',
    (t) async {
      await open(t);
      await pick(t, const Key('template-water'));
      await t.enterText(find.byKey(const Key('habit-target')), '1800');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await pick(t, const Key('save-entry'));
      final h = (await store.habits()).single;
      expect(h.icon, 1);
      expect(h.kind, HabitKind.quantity);
      expect(h.target, 1800000);
      expect(h.unit, 'ml');
      expect((await store.plans()).single.target, 1800000);
      expect(await store.entries(), isEmpty);
      expect(await store.cards(), isEmpty);
      final snap = await store.exportSnapshot();
      await store.restoreSnapshot(snap);
      expect((await store.habits()).single.target, 1800000);
    },
  );
  testWidgets(
    'custom name suggests icon but manual selection survives later typing',
    (t) async {
      await open(t);
      await pick(t, const Key('custom-habit'));
      await t.enterText(find.byKey(const Key('entry-title')), 'Read a page');
      await t.pumpAndSettle();
      expect(
        t
            .widgetList<HabitIcon>(find.byType(HabitIcon))
            .any((i) => i.index == 2),
        isTrue,
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await pick(t, const Key('habit-icon-18'));
      await Scrollable.ensureVisible(
        t.element(find.byKey(const Key('entry-title'))),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('entry-title')), 'Drink water');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await pick(t, const Key('save-entry'));
      final h = (await store.habits()).single;
      expect(h.icon, 18);
      expect(h.kind, HabitKind.check);
    },
  );
  testWidgets('catalog opened before restore cannot create in new generation', (
    t,
  ) async {
    await open(t);
    final snap = await store.exportSnapshot();
    await app.run(() => store.restoreSnapshot(snap));
    await pick(t, const Key('template-reading'));
    await pick(t, const Key('save-entry'));
    expect(await store.habits(), isEmpty);
  });
  testWidgets('search filters templates and cancel never creates a habit', (
    t,
  ) async {
    await open(t);
    await t.enterText(find.byKey(const Key('template-search')), 'water');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('template-water')), findsOneWidget);
    expect(find.byKey(const Key('template-reading')), findsNothing);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(await store.habits(), isEmpty);
  });
  testWidgets('existing icon changes only after applying the suggestion', (
    t,
  ) async {
    final h = Habit(
      id: 'old',
      title: 'Drink water',
      kind: HabitKind.quantity,
      startDay: app.today,
      target: 2000000,
      unit: 'ml',
      icon: 0,
    );
    await store.saveHabit(h, create: true);
    await store.setRecord(h.id, app.today, 250000, today: app.today);
    await app.load();
    await t.pumpWidget(
      shell(
        child: Scaffold(
          body: EntryEditor(app: app, type: 'habit', habit: h),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect((await store.habits()).single.icon, 0);
    await pick(t, const Key('apply-suggested-icon'));
    await pick(t, const Key('save-entry'));
    final saved = (await store.habits()).single;
    expect(saved.icon, 1);
    expect(saved.target, 2000000);
    expect(saved.unit, 'ml');
    expect((await store.entries()).single.value, 250000);
    expect((await store.plans()).length, 1);
  });
  for (final lang in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$lang dark=$dark catalog narrow large text and keyboard keeps custom reachable',
        (t) async {
          t.view.physicalSize = const Size(320, 800);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(t.view.resetViewInsets);
          await t.pumpWidget(
            shell(language: lang, dark: dark, child: const HabitCatalog()),
          );
          await t.pumpAndSettle();
          t.view.viewInsets = const FakeViewPadding(bottom: 280);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(
            find.byKey(const Key('custom-habit')).hitTestable(),
            findsOneWidget,
          );
        },
      );
    }
  }
}
