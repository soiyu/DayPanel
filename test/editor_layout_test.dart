import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/main.dart';

void main() {
  sqfliteFfiInit();
  for (final locale in ['zh', 'en']) {
    testWidgets(
      '$locale editor keeps actions reachable with large text and keyboard',
      (tester) async {
        final store = await AppStore.open(
          factory: databaseFactoryFfiNoIsolate,
          path: inMemoryDatabasePath,
        );
        final app = AppController(
          store,
          clock: () => DateTime(2026, 11, 5, 12),
        );
        await store.preference('locale', locale);
        await app.load();
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(() async {
          app.dispose();
          await store.close();
        });
        await tester.pumpWidget(DayPanelApp(app: app));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('add-entry')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byKey(const Key('entry-title')), 'Reading');
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('save-entry')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('save-entry')));
        await tester.pumpAndSettle();
        expect(app.habits.single.title, 'Reading');
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'quantity presets fill total only; cancellation leaves the database unchanged',
    (tester) async {
      final store = await AppStore.open(
        factory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      final app = AppController(store, clock: () => DateTime(2026, 11, 5, 12));
      await store.saveHabit(
        Habit(
          id: 'water',
          title: 'Water',
          kind: HabitKind.quantity,
          startDay: app.today,
          target: 2000000,
          unit: 'ml',
        ),
        create: true,
      );
      await store.setRecord('water', app.today, 250000, today: app.today);
      await app.load();
      addTearDown(() async {
        app.dispose();
        await store.close();
      });
      await tester.pumpWidget(DayPanelApp(app: app));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Log'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('500 ml'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('500 ml'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('quantity-input')))
            .controller!
            .text,
        '500',
      );
      expect((await store.entries()).single.value, 250000);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await store.entries()).single.value, 250000);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
