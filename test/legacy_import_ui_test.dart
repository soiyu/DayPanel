import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/legacy_files.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/legacy_import.dart';
import 'package:daypanel/presentation/components.dart';
import 'package:daypanel/presentation/theme.dart';
import 'support/legacy_fixture.dart';

class FakeLegacyFiles implements LegacyFiles {
  Map<Object?, Object?>? data;
  @override
  Future<Map<Object?, Object?>?> pick() async => data;
}

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late FakeLegacyFiles files;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => DateTime(2026, 11, 6));
    files = FakeLegacyFiles()..data = legacyFixture();
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell({String locale = 'en', bool dark = false}) => MaterialApp(
    theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          child: const Text('Open'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => LegacyImportPage(app: app, files: files),
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> open(
    WidgetTester t, {
    String locale = 'en',
    bool dark = false,
  }) async {
    await t.pumpWidget(shell(locale: locale, dark: dark));
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    final pick = find.byKey(const Key('legacy-pick'));
    await t.scrollUntilVisible(
      pick,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      t.element(pick),
      alignment: .4,
      duration: Duration.zero,
    );
    await t.pumpAndSettle();
    await t.tap(pick);
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String key) async {
    final f = find.byKey(Key(key));
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        key == 'legacy-pick' ? -200 : 200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(
      t.element(f),
      alignment: .4,
      duration: Duration.zero,
    );
    await t.pumpAndSettle();
    expect(f.hitTestable(), findsOneWidget);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets(
    'preview cancellation leaves records settings generation and recovery unchanged',
    (t) async {
      await store.saveTask(
        const SmallTask(id: 't', title: 'Keep'),
        create: true,
      );
      await app.load();
      final before = await store.exportSnapshot();
      await open(t);
      expect(await store.habits(), isEmpty);
      expect(find.byKey(const Key('legacy-commit')), findsNothing);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect((await store.exportSnapshot()).tables, before.tables);
      expect(await store.generation(), 0);
    },
  );
  testWidgets(
    'subset explicit confirmation imports and second preview marks duplicates',
    (t) async {
      await open(t);
      await tap(t, 'legacy-select-2');
      await tap(t, 'legacy-next');
      await tap(t, 'legacy-acknowledge');
      await tap(t, 'legacy-commit');
      expect(app.habits.length, 1);
      expect(app.habits.single.title, 'Old reading');
      expect(app.cards, isEmpty);
      await tap(t, 'legacy-pick');
      await tap(t, 'legacy-select-1');
      expect(
        t
            .widget<CheckboxListTile>(find.byKey(const Key('legacy-select-1')))
            .onChanged,
        isNull,
      );
      expect(app.habits.length, 1);
    },
  );
  testWidgets('rolling frequency requires explicit schedule and valid count', (
    t,
  ) async {
    files.data = legacyFixture(rolling: true);
    await open(t);
    expect(
      t.widget<AppAction>(find.byKey(const Key('legacy-next'))).onTap,
      isNull,
    );
    await tap(t, 'legacy-schedule-1');
    await tap(t, 'legacy-rule-weekly');
    await t.enterText(find.byKey(const Key('legacy-count')), '8');
    await tap(t, 'legacy-rule-save');
    expect(find.byKey(const Key('legacy-count')), findsOneWidget);
    await t.enterText(find.byKey(const Key('legacy-count')), '2');
    await tap(t, 'legacy-rule-save');
    await tap(t, 'legacy-next');
    await tap(t, 'legacy-acknowledge');
    await tap(t, 'legacy-commit');
    expect(app.habits.first.schedule, ScheduleKind.weekly);
    expect(app.habits.first.weeklyGoal, 2);
  });
  testWidgets(
    'cancelled new file selection does not authorize stale preview after restore',
    (t) async {
      await open(t);
      await tap(t, 'legacy-next');
      await tap(t, 'legacy-acknowledge');
      final snap = await store.exportSnapshot();
      await app.run(() => store.restoreSnapshot(snap));
      files.data = null;
      await tap(t, 'legacy-change-file');
      await tap(t, 'legacy-commit');
      expect(await store.habits(), isEmpty);
      expect(find.textContaining('Import could not finish.'), findsOneWidget);
    },
  );
  testWidgets('bad file and unsupported target are visible without writes', (
    t,
  ) async {
    files.data = {'version': 99};
    await open(t);
    expect(find.textContaining('The file is damaged'), findsOneWidget);
    final raw = jsonDecode(jsonEncode(legacyFixture())) as Map;
    raw['habits'][1]['target_type'] = 1;
    files.data = raw.cast<Object?, Object?>();
    await tap(t, 'legacy-pick');
    await tap(t, 'legacy-select-2');
    expect(
      t
          .widget<CheckboxListTile>(find.byKey(const Key('legacy-select-2')))
          .onChanged,
      isNull,
    );
    expect(await store.habits(), isEmpty);
  });
  for (final locale in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$locale dark=$dark import preview fits 320dp 160% with reachable actions',
        (t) async {
          t.view.physicalSize = const Size(320, 800);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          await open(t, locale: locale, dark: dark);
          await tap(t, 'legacy-next');
          await tap(t, 'legacy-acknowledge');
          expect(t.takeException(), isNull);
          expect(
            find.byKey(const Key('legacy-commit')).hitTestable(),
            findsOneWidget,
          );
          await tap(t, 'legacy-commit');
          expect(app.habits.length, 2);
        },
      );
    }
  }
}
