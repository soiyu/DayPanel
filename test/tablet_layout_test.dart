import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/main.dart';
import 'package:daypanel/presentation/components.dart';

void main() {
  sqfliteFfiInit();

  Future<(AppStore, AppController)> setupApp() async {
    final store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    final app = AppController(store, clock: () => DateTime(2026, 11, 7));
    await store.saveHabit(
      Habit(
        id: 'h1',
        title: 'Morning Yoga',
        kind: HabitKind.check,
        startDay: app.today,
        icon: 1,
      ),
      create: true,
    );
    await store.saveTask(
      SmallTask(id: 't1', title: 'Review proposal', dueDay: app.today),
      create: true,
    );
    await store.saveNote(
      Note(id: 'n1', body: 'Mindful thoughts today.', day: app.today),
      create: true,
    );
    await app.load();
    return (store, app);
  }

  testWidgets(
    'tablet portrait 800x1280 renders GlassSideNavigation and hides bottom navigation',
    (t) async {
      final (store, app) = await setupApp();
      t.view.physicalSize = const Size(800, 1280);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(() async {
        app.dispose();
        await store.close();
      });

      await t.pumpWidget(DayPanelApp(app: app));
      await t.pumpAndSettle();

      expect(find.byType(GlassSideNavigation), findsOneWidget);
      expect(find.byType(GlassNavigation), findsNothing);

      for (var i = 0; i < 4; i++) {
        expect(find.byKey(Key('tab-$i')), findsOneWidget);
      }

      await t.tap(find.byKey(const Key('tab-1')));
      await t.pumpAndSettle();
      expect(find.text('Review proposal'), findsOneWidget);

      await t.tap(find.byKey(const Key('tab-2')));
      await t.pumpAndSettle();
      expect(find.text('Mindful thoughts today.'), findsOneWidget);

      await t.tap(find.byKey(const Key('tab-3')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('settings-habits')), findsOneWidget);
    },
  );

  testWidgets(
    'tablet landscape 1280x800 renders GlassSideNavigation and centers content within bounds',
    (t) async {
      final (store, app) = await setupApp();
      t.view.physicalSize = const Size(1280, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(() async {
        app.dispose();
        await store.close();
      });

      await t.pumpWidget(DayPanelApp(app: app));
      await t.pumpAndSettle();

      expect(find.byType(GlassSideNavigation), findsOneWidget);
      expect(find.byType(GlassNavigation), findsNothing);

      final habit = find.byKey(const Key('habit-action-h1'));
      expect(habit.hitTestable(), findsOneWidget);
      final habitRect = t.getRect(habit);
      expect(habitRect.left, greaterThan(82.0));
    },
  );

  testWidgets('phone viewport 390x844 maintains GlassNavigation at bottom', (
    t,
  ) async {
    final (store, app) = await setupApp();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(() async {
      app.dispose();
      await store.close();
    });

    await t.pumpWidget(DayPanelApp(app: app));
    await t.pumpAndSettle();

    expect(find.byType(GlassNavigation), findsOneWidget);
    expect(find.byType(GlassSideNavigation), findsNothing);
  });
}
