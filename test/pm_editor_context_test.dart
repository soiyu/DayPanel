import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/components.dart';
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late Habit water;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => DateTime(2026, 11, 8));
    water = Habit(
      id: 'water',
      title: 'Drink water',
      kind: HabitKind.quantity,
      startDay: app.today.plus(-3),
      target: 1500000,
      unit: 'ml',
      icon: 1,
    );
    await store.saveHabit(water, create: true);
    await store.setRecord(water.id, app.today, 500000, today: app.today);
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });

  Widget shell(Widget child, {String locale = 'en', bool dark = false}) =>
      MaterialApp(
        locale: Locale(locale),
        theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
  Future<void> tap(WidgetTester t, Finder f) async {
    await Scrollable.ensureVisible(t.element(f), alignment: .35);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> quantity(WidgetTester t) async {
    await t.pumpWidget(
      shell(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => openQuantity(context, app, water, app.today),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
  }

  testWidgets(
    'quick total is a replacement draft until confirmed, not a new intake',
    (t) async {
      await quantity(t);
      await tap(t, find.text('250 ml'));
      expect((await store.entries()).single.value, 500000);
      expect(
        t
            .widget<TextField>(find.byKey(const Key('quantity-input')))
            .controller!
            .text,
        '250',
      );
      final preview = t
          .widget<Text>(find.byKey(const Key('quantity-replace-preview')))
          .data!;
      expect(preview, contains('250 ml'));
      expect(preview, contains('does not add'));
      await tap(t, find.byKey(const Key('quantity-save')));
      expect((await store.entries()).single.value, 250000);
      expect(await store.cards(), isEmpty);
    },
  );
  testWidgets('cancel and stale quantity page preserve saved total', (t) async {
    await quantity(t);
    await tap(t, find.text('250 ml'));
    await tap(t, find.text('Cancel').last);
    expect((await store.entries()).single.value, 500000);
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    await tap(t, find.text('250 ml'));
    final snapshot = await store.exportSnapshot();
    await app.run(() => store.restoreSnapshot(snapshot));
    await tap(t, find.byKey(const Key('quantity-save')));
    expect((await store.entries()).single.value, 500000);
    expect(find.byKey(const Key('quantity-input')), findsOneWidget);
  });
  testWidgets(
    'existing type is read only and advanced settings are progressively disclosed',
    (t) async {
      await t.pumpWidget(
        shell(EntryEditor(app: app, type: 'habit', habit: water)),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('habit-type-readonly')), findsOneWidget);
      expect(find.text('Check off'), findsNothing);
      expect(
        t.getTopLeft(find.byKey(const Key('plan-tomorrow-target'))).dy,
        lessThan(t.getTopLeft(find.byKey(const Key('habit-target'))).dy),
      );
      expect(find.byKey(const Key('habit-icon-18')), findsNothing);
      final advanced = find.byKey(const Key('habit-advanced-settings'));
      await tap(
        t,
        find.descendant(of: advanced, matching: find.byType(ExpansionTile)),
      );
      await tap(t, find.byKey(const Key('habit-icon-18')));
      await tap(t, find.byKey(const Key('save-entry')));
      final changed = (await store.habits()).single;
      expect(changed.kind, HabitKind.quantity);
      expect(changed.icon, 18);
      expect(changed.target, 1500000);
      expect(changed.unit, 'ml');
      expect((await store.entries()).single.value, 500000);
      expect((await store.plans()).length, 1);
    },
  );
  for (final resident in [false, true]) {
    testWidgets('existing task type is read only resident=$resident', (
      t,
    ) async {
      final task = SmallTask(
        id: 'task',
        title: 'A task',
        resident: resident,
        startDay: resident ? app.today : null,
      );
      await store.saveTask(task, create: true);
      await app.load();
      await t.pumpWidget(
        shell(EntryEditor(app: app, type: 'task', task: task)),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('task-type-readonly')), findsOneWidget);
      expect(find.text(resident ? 'One-time' : 'Resident'), findsNothing);
      await t.enterText(find.byKey(const Key('entry-title')), 'Renamed');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('save-entry')));
      final saved = (await store.tasks()).single;
      expect(saved.resident, resident);
      expect(saved.title, 'Renamed');
    });
  }
  testWidgets('quantity save cannot be submitted twice while waiting', (
    t,
  ) async {
    final waiting = Completer<bool>();
    var writes = 0;
    await t.pumpWidget(
      shell(
        QuantityEditor(
          app: app,
          habit: water,
          day: app.today,
          onSave: (_) {
            writes++;
            return waiting.future;
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('quantity-save')));
    await t.pump();
    final save = t.widget<AppAction>(find.byKey(const Key('quantity-save')));
    expect(save.onTap, isNull);
    expect(save.busy, isTrue);
    expect(writes, 1);
    waiting.complete(false);
    await t.pumpAndSettle();
    expect((await store.entries()).single.value, 500000);
  });
  for (final locale in ['en', 'zh']) {
    testWidgets('$locale 320dp 160% quantity input stays first with keyboard', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 800);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(t.view.resetViewInsets);
      await t.pumpWidget(
        shell(
          QuantityEditor(app: app, habit: water, day: app.today),
          locale: locale,
          dark: true,
        ),
      );
      await t.pumpAndSettle();
      expect(
        t.getTopLeft(find.byKey(const Key('quantity-input'))).dy,
        lessThan(
          t.getTopLeft(find.byKey(const Key('quantity-saved-summary'))).dy,
        ),
      );
      t.view.viewInsets = const FakeViewPadding(bottom: 280);
      await t.pumpAndSettle();
      expect(
        find.byKey(const Key('quantity-save')).hitTestable(),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  }
}
