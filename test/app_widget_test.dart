import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/main.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => DateTime(2026, 11, 5, 12));
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });

  testWidgets('first run is empty, creates a real habit, logs and reopens it', (
    tester,
  ) async {
    await tester.pumpWidget(DayPanelApp(app: app));
    await tester.pumpAndSettle();
    expect(find.text('Make room for a small habit'), findsOneWidget);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('entry-title')), 'Read a page');
    await tester.ensureVisible(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    expect(app.habits.single.title, 'Read a page');
    expect(find.text('Read a page'), findsOneWidget);
    await tester.ensureVisible(find.text('Complete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();
    expect(app.entries.single.value, 1000);
    await tester.tap(find.text('Reopen'));
    await tester.pumpAndSettle();
    expect(app.entries, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('quantity opening and cancelling never writes', (tester) async {
    await store.saveHabit(
      Habit(
        id: 'h',
        title: 'Water',
        kind: HabitKind.quantity,
        startDay: app.today,
        target: 2000000,
        unit: 'ml',
      ),
      create: true,
    );
    await app.load();
    await tester.pumpWidget(DayPanelApp(app: app));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    expect(app.entries, isEmpty);
    await tester.enterText(find.byKey(const Key('quantity-input')), '0.001');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(app.entries, isEmpty);
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quantity-input')), '250.001');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(app.entries.single.value, 250001);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('task and journal forms persist real content', (tester) async {
    await tester.pumpWidget(DayPanelApp(app: app));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.checklist_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('entry-title')),
      'Return the book',
    );
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    expect(app.tasks.single.title, 'Return the book');
    expect(app.tasks.single.dueDay, isNull);
    await tester.tap(find.byTooltip('Complete'));
    await tester.pumpAndSettle();
    expect(app.tasks.single.completedDay, app.today);
    await tester.tap(find.byIcon(Icons.auto_stories_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('entry-title')),
      'A small moment worth remembering.',
    );
    await tester.ensureVisible(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-entry')));
    await tester.pumpAndSettle();
    expect(app.notes.single.body, 'A small moment worth remembering.');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tab navigation keeps each list scroll position independent', (
    tester,
  ) async {
    for (var i = 0; i < 12; i++) {
      await store.saveTask(SmallTask(id: '$i', title: 'Task $i'), create: true);
    }
    await app.load();
    await tester.pumpWidget(DayPanelApp(app: app));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-1')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('taskList')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    final taskScroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    expect(taskScroll, greaterThan(100));
    await tester.tap(find.byKey(const Key('tab-3')));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      0,
    );
    await tester.tap(find.byKey(const Key('tab-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      closeTo(taskScroll, 1),
    );
    await tester.pumpWidget(const SizedBox());
  });

  for (final locale in ['zh', 'en']) {
    for (final theme in ['light', 'dark']) {
      testWidgets(
        '$locale $theme at 320dp and 160% text keeps every page usable',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await store.preference('locale', locale);
          await store.preference('theme', theme);
          await store.saveHabit(
            Habit(
              id: 'h',
              title: '这是一个很长的习惯名称 A little reading every day',
              kind: HabitKind.check,
              startDay: app.today,
            ),
            create: true,
          );
          await store.saveTask(
            SmallTask(
              id: 't',
              title: 'Read this long task name then put the book away',
            ),
            create: true,
          );
          await store.saveNote(
            Note(id: 'n', body: '记录生活里值得记住的一件小事。 A note.', day: app.today),
            create: true,
          );
          await app.load();
          await tester.pumpWidget(DayPanelApp(app: app));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final icon in [
            Icons.checklist_rounded,
            Icons.auto_stories_outlined,
            Icons.person_outline_rounded,
          ]) {
            await tester.tap(find.byIcon(icon).last);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.ensureVisible(
            find.text(locale == 'zh' ? '七日回顾' : 'Seven-day review'),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(locale == 'zh' ? '七日回顾' : 'Seven-day review'),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.text(locale == 'zh' ? '外观' : 'Appearance'),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(locale == 'zh' ? '外观' : 'Appearance'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(locale == 'zh' ? '取消' : 'Cancel'));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text(locale == 'zh' ? '管理习惯' : 'Manage habits'),
            -180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(locale == 'zh' ? '管理习惯' : 'Manage habits'),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('这是一个很长的习惯名称 A little reading every day'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
