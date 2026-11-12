import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/plus_access.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/home.dart';
import 'package:daypanel/presentation/insights.dart';
import 'package:daypanel/presentation/plus_page.dart';
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
    app = AppController(store, clock: () => DateTime(2026, 11, 11, 12));
    await store.saveHabit(
      Habit(
        id: 'read',
        title: 'Read a chapter',
        kind: HabitKind.check,
        startDay: app.today.plus(-120),
      ),
      create: true,
      today: app.today,
    );
    for (var i = 1; i <= 10; i++) {
      await store.setRecord('read', app.today.plus(-i), 1000, today: app.today);
    }
    await store.saveNote(
      Note(id: 'note', body: 'A useful note.', day: app.today.plus(-2)),
      create: true,
      today: app.today,
    );
    await app.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          PlusAccess.channel,
          (call) async => {'owned': false, 'available': false},
        );
  });

  tearDown(() async {
    app.dispose();
    await store.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PlusAccess.channel, null);
  });

  Widget shell(Widget child, {String language = 'en'}) => MaterialApp(
    locale: Locale(language),
    theme: dayPanelTheme(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('locked page explains Plus and opens the purchase page', (
    tester,
  ) async {
    app.plus.testing = false;
    await tester.pumpWidget(shell(InsightsPage(app: app)));
    await tester.pumpAndSettle();

    final s = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(find.text(s.insightsLockedTitle), findsOneWidget);
    expect(find.byKey(const Key('insights-range-30')), findsNothing);

    await tap(tester, find.byKey(const Key('insights-unlock')));
    expect(find.byType(PlusPage), findsOneWidget);
    expect(find.text(s.plusTitle), findsOneWidget);

    // A purchase can finish while the Plus page is still open. Returning must
    // reveal the report without requiring the user to re-enter the page.
    app.plus.owned = true;
    app.plus.notifyListeners();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('insights-range-30')), findsOneWidget);
    expect(find.text(s.insightsLockedTitle), findsNothing);
  });

  testWidgets('report shows completion, habit and journal evidence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(shell(InsightsPage(app: app)));
    await tester.pumpAndSettle();

    final s = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(find.text(s.insightsRate), findsOneWidget);
    expect(find.text('33%'), findsWidgets);
    expect(find.text(s.insightsHabitsTitle), findsOneWidget);
    expect(find.text('Read a chapter'), findsWidgets);
    expect(find.textContaining('1 notes'), findsOneWidget);

    await tap(tester, find.byKey(const Key('insights-range-90')));
    expect(find.text('11%'), findsWidgets);
  });

  testWidgets('home row opens insights', (tester) async {
    await tester.pumpWidget(shell(HomePage(app: app)));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const Key('tab-3')));

    final row = find.byKey(const Key('home-insights'));
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 40,
    );
    await tap(tester, row);
    expect(find.byType(InsightsPage), findsOneWidget);
  });
}
