import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/home_widgets.dart';
import 'package:daypanel/presentation/theme.dart';
import 'home_widgets_test.dart' show FakeWidgets;

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late FakeWidgets platform;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    platform = FakeWidgets();
    app = AppController(
      store,
      clock: () => DateTime(2026, 11, 6),
      widgetPlatform: platform,
    );
    await store.saveHabit(
      Habit(
        id: 'h',
        title: 'A little reading',
        kind: HabitKind.check,
        startDay: app.today,
      ),
      create: true,
    );
    await store.saveHabit(
      Habit(
        id: 'q',
        title: 'Water',
        kind: HabitKind.quantity,
        startDay: app.today,
        target: 2000000,
        unit: 'ml',
      ),
      create: true,
    );
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell(
    Map<String, Object?> request, {
    String locale = 'en',
    bool dark = false,
    double scale = 1,
  }) => MaterialApp(
    locale: Locale(locale),
    theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: WidgetFlow(app: app, request: request),
  );
  Map<String, Object?> config(int id) => {
    'mode': 'configure',
    'widgetId': id,
    'kind': 'habit',
  };
  Map<String, Object?> quantity() => {
    'mode': 'quantity',
    'widgetId': 4,
    'kind': 'habit',
    'id': 'q',
    'generation': 0,
    'day': app.today.key,
    'token': 'test',
  };
  testWidgets(
    'selection is saved for exact widget id only; cancel does not configure',
    (tester) async {
      await tester.pumpWidget(shell(config(12)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Water'));
      await tester.pumpAndSettle();
      expect(platform.configs, isEmpty);
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(platform.configs, [(12, 'q', 0)]);
      expect(platform.closes, 1);
      await tester.pumpWidget(const SizedBox());
      app.closing = false;
      await tester.pumpWidget(shell(config(13)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(platform.configs.length, 1);
      expect(platform.closes, 2);
    },
  );
  testWidgets('quantity opens directly; cancelling writes nothing', (
    tester,
  ) async {
    await tester.pumpWidget(shell(quantity()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quantity-input')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await store.entries(), isEmpty);
    expect(platform.closes, 1);
  });
  testWidgets('quantity confirmation saves total once and returns home', (
    tester,
  ) async {
    await tester.pumpWidget(shell(quantity()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quantity-input')), '250.001');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await store.entries()).single.value, 250001);
    expect(platform.closes, 1);
  });
  testWidgets('old quantity page after restore rejects write', (tester) async {
    await tester.pumpWidget(shell(quantity()));
    await tester.pumpAndSettle();
    final snap = await store.exportSnapshot();
    await app.run(() => store.restoreSnapshot(snap));
    await tester.enterText(find.byKey(const Key('quantity-input')), '10');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await store.entries(), isEmpty);
    expect(platform.closes, 0);
  });
  testWidgets('stale native action displays real escape without writing', (
    tester,
  ) async {
    platform.valid = false;
    await tester.pumpWidget(
      shell({...quantity(), 'mode': 'complete', 'id': 'h'}),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('The content or date changed.'), findsOneWidget);
    expect(await store.entries(), isEmpty);
    await tester.tap(find.text('Return to home screen'));
    await tester.pumpAndSettle();
    expect(platform.closes, 1);
  });
  for (final locale in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets('widget configuration $locale dark=$dark 320dp 160% text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          shell(config(12), locale: locale, dark: dark, scale: 1.6),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(locale == 'en' ? 'Save' : '保存'), findsOneWidget);
        await tester.tap(find.text(locale == 'en' ? 'Cancel' : '取消'));
        await tester.pumpAndSettle();
        expect(platform.closes, 1);
      });
    }
  }
}
