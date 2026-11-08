import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/appearance.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/appearance.dart';
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/theme.dart';
import 'home_widgets_test.dart' show FakeWidgets;

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late FakeWidgets widgets;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    widgets = FakeWidgets();
    app = AppController(
      store,
      clock: () => DateTime(2026, 11, 6),
      widgetPlatform: widgets,
    );
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell({
    String locale = 'en',
    bool dark = false,
    bool editor = false,
  }) => MaterialApp(
    theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => editor
              ? openEditor(context, app, 'habit')
              : Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => editor
                        ? Scaffold(
                            body: EntryEditor(app: app, type: 'habit'),
                          )
                        : AppearancePage(app: app),
                  ),
                ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  Future<void> open(
    WidgetTester tester, {
    String locale = 'en',
    bool dark = false,
    bool editor = false,
  }) async {
    await tester.pumpWidget(shell(locale: locale, dark: dark, editor: editor));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    if (editor) {
      await tester.tap(find.byKey(const Key('custom-habit')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> pick(WidgetTester tester, String key) async {
    if (key.startsWith('habit-icon-') ||
        key.startsWith('habit-color-') ||
        key.startsWith('habit-frame-')) {
      final advanced = find.byKey(const Key('habit-advanced-settings'));
      if (advanced.evaluate().isNotEmpty &&
          find.byKey(Key(key)).evaluate().isEmpty) {
        await Scrollable.ensureVisible(tester.element(advanced), alignment: .4);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: advanced, matching: find.byType(ExpansionTile)),
        );
        await tester.pumpAndSettle();
      }
    }
    final finder = find.byKey(Key(key));
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        180,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignment: .4,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    expect(finder.hitTestable(), findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'preview choices and reset never persist when cancelled or system back',
    (tester) async {
      await open(tester);
      await pick(tester, 'palette-teal');
      await pick(tester, 'font-serif');
      await pick(tester, 'frame-ring');
      expect(await store.settings(), isEmpty);
      expect(widgets.refreshes, 0);
      await pick(tester, 'appearance-reset');
      expect(await store.settings(), isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await store.settings(), isEmpty);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await pick(tester, 'palette-violet');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(await store.settings(), isEmpty);
    },
  );
  testWidgets('save applies all choices atomically and refreshes widgets', (
    tester,
  ) async {
    await open(tester);
    await pick(tester, 'mode-dark');
    await pick(tester, 'palette-teal');
    await pick(tester, 'font-serif');
    await pick(tester, 'frame-ring');
    await pick(tester, 'appearance-save');
    expect(
      Appearance.fromSettings(await store.settings()).toSettings(),
      const Appearance(
        mode: 'dark',
        palette: 'teal',
        font: 'serif',
        frame: 'ring',
      ).toSettings(),
    );
    expect(widgets.refreshes, 1);
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets('restore during preview rejects obsolete save', (tester) async {
    await open(tester);
    await pick(tester, 'palette-violet');
    final snap = await store.exportSnapshot();
    await app.run(() => store.restoreSnapshot(snap));
    await pick(tester, 'appearance-save');
    expect(await store.settings(), isEmpty);
    expect(find.byType(AppearancePage), findsOneWidget);
  });
  testWidgets(
    'habit style picker saves named icon color and frame without a completion',
    (tester) async {
      await open(tester, editor: true);
      await tester.enterText(find.byKey(const Key('entry-title')), 'Stretch');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await pick(tester, 'habit-icon-23');
      await pick(tester, 'habit-color-rose');
      await pick(tester, 'habit-frame-ring');
      await pick(tester, 'save-entry');
      final h = (await store.habits()).single;
      expect(h.icon, 23);
      expect(h.color, 'rose');
      expect(h.frame, 'ring');
      expect(await store.entries(), isEmpty);
      expect((await store.plans()).length, 1);
    },
  );
  for (final locale in ['zh', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$locale dark=$dark preview with serif at 320dp 160% stays usable',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await open(tester, locale: locale, dark: dark);
          await pick(tester, dark ? 'mode-dark' : 'mode-light');
          await pick(tester, 'palette-violet');
          await pick(tester, 'font-serif');
          await pick(tester, 'frame-ring');
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('appearance-save')).hitTestable(),
            findsOneWidget,
          );
          await pick(tester, 'appearance-save');
          expect(Appearance.fromSettings(await store.settings()).font, 'serif');
        },
      );
    }
  }
  testWidgets('24 icon choices keep semantic names and selected state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: dayPanelTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HabitStylePicker(
              icon: 23,
              color: 'rose',
              frame: 'ring',
              title: 'Care',
              onIcon: (_) {},
              onColor: (_) {},
              onFrame: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Care'), findsWidgets);
    expect(find.bySemanticsLabel('Water'), findsOneWidget);
    expect(find.byKey(const Key('habit-icon-23')), findsOneWidget);
    semantics.dispose();
  });
}
