import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/plus_access.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/components.dart';
import 'package:daypanel/presentation/home.dart';
import 'package:daypanel/presentation/plus_page.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  sqfliteFfiInit();

  Widget shell(Widget child, {String locale = 'zh'}) => MaterialApp(
    locale: Locale(locale),
    theme: dayPanelTheme(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  group('Habits week bar layout', () {
    testWidgets(
      'all 7 weekdays including Sunday fit cleanly on narrow 320dp screen without overflow',
      (t) async {
        final store = await AppStore.open(
          factory: databaseFactoryFfiNoIsolate,
          path: inMemoryDatabasePath,
        );
        final app = AppController(store);
        await app.load();
        addTearDown(() async {
          app.dispose();
          await store.close();
        });

        // Test on narrow 320dp screen (where horizontal padding is 20 on each side = 280dp available)
        t.view.physicalSize = const Size(320, 700);
        t.view.devicePixelRatio = 1.0;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);

        await t.pumpWidget(shell(HomePage(app: app), locale: 'zh'));
        await t.pumpAndSettle();

        // There should be no Flutter layout overflow exceptions
        expect(t.takeException(), isNull);

        // Find the 7 day cells in the week bar (Row of 7 Expanded)
        final days = List.generate(
          7,
          (i) => app.selectedDay.plus(i - (app.selectedDay.date.weekday - 1)),
        );
        for (final d in days) {
          final dayFinder = find.text('${d.date.day}');
          expect(dayFinder, findsWidgets);

          // Verify the Sunday cell (last day of the week) is fully within screen bounds
          final sundayElement = t.getRect(dayFinder.first);
          expect(sundayElement.left, greaterThanOrEqualTo(0));
          expect(sundayElement.right, lessThanOrEqualTo(320.0));
        }

        // Tapping Sunday selects Sunday
        final sunday = days[6];
        final sundayCell = find.text('${sunday.date.day}').first;
        await t.tap(sundayCell);
        await t.pumpAndSettle();
        expect(app.selectedDay, sunday);

        await t.pumpWidget(const SizedBox());
      },
    );
  });

  group('Plus test access and restore', () {
    testWidgets(
      'in test build restore and retry successfully unlock Plus features',
      (t) async {
        final store = await AppStore.open(
          factory: databaseFactoryFfiNoIsolate,
          path: inMemoryDatabasePath,
        );
        final app = AppController(store);
        await app.load();
        addTearDown(() async {
          app.dispose();
          await store.close();
        });

        // Set mock channel to simulate locked free state initially
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(PlusAccess.channel, (call) async {
              if (call.method == 'restore' || call.method == 'buy') {
                return {'testing': true, 'owned': true, 'available': true};
              }
              return {'testing': false, 'owned': false, 'available': false};
            });

        // Initially if plus is not enabled:
        t.view.physicalSize = const Size(800, 1200);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);

        app.plus.testing = false;
        app.plus.owned = false;
        expect(app.plus.enabled, isFalse);

        await t.pumpWidget(shell(PlusPage(app: app), locale: 'zh'));
        await t.pumpAndSettle();

        // Plus remains disabled on initial load of free state
        expect(app.plus.enabled, isFalse);

        // Tap restore purchase
        final restoreButton = find.widgetWithText(AppAction, '恢复购买');
        expect(restoreButton, findsOneWidget);
        await t.ensureVisible(restoreButton);
        await t.tap(restoreButton);
        await t.pumpAndSettle();

        // Plus is now enabled
        expect(app.plus.enabled, isTrue);
        // Shows VIP hero card
        expect(find.text('✦ DayPanel Plus 终身会员'), findsOneWidget);

        await t.pumpWidget(const SizedBox());
      },
    );
  });
}
