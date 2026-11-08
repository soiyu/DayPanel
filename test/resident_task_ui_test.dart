import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/main.dart';
import 'package:daypanel/presentation/tasks.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late DateTime clock;
  setUp(() async {
    clock = DateTime(2026, 11, 6, 23, 59);
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => clock);
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell(Widget child, {String language = 'en', bool dark = false}) =>
      MaterialApp(
        locale: Locale(language),
        theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );
  testWidgets(
    'create resident, complete today, and next day is unlogged without erasing yesterday',
    (tester) async {
      await tester.pumpWidget(DayPanelApp(app: app));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-entry')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('entry-title')),
        'Water plants',
      );
      await tester.ensureVisible(find.text('Keep around'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep around'));
      await tester.pumpAndSettle();
      expect(find.text('Planned date'), findsNothing);
      await tester.tap(find.byKey(const Key('save-entry')));
      await tester.pumpAndSettle();
      expect(app.tasks.single.resident, isTrue);
      await tester.ensureVisible(find.byTooltip('Complete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Complete'));
      await tester.pumpAndSettle();
      expect(app.taskEntries.single.day, Day.parse('2026-11-06'));
      expect(find.text('Done today'), findsOneWidget);
      clock = DateTime(2026, 11, 7, 0, 1);
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.text('Not logged today'), findsOneWidget);
      expect(app.taskEntries.length, 1);
      expect(app.tasks.length, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'history correction archive and unarchive use actual stored records',
    (tester) async {
      final first = Day.parse('2026-11-05');
      final task = SmallTask(
        id: 'r',
        title: 'Tidy up',
        resident: true,
        startDay: first,
      );
      await store.saveTask(task, create: true, today: first);
      await store.setResidentRecord('r', first, true, today: app.today);
      await store.setResidentRecord('r', app.today, true, today: app.today);
      await app.load();
      await tester.pumpWidget(
        shell(ResidentTaskPage(app: app, id: 'r', initialDay: first)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('resident-record')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resident-record')));
      await tester.pumpAndSettle();
      expect(app.taskEntries.single.day, app.today);
      await tester.scrollUntilVisible(
        find.byKey(const Key('task-management')),
        180,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('More actions'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Archive'), 180);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(app.tasks.single.archived, isTrue);
      expect(app.taskEntries.length, 1);
      await tester.tap(find.text('Unarchive'));
      await tester.pumpAndSettle();
      expect(app.tasks.single.archived, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final language in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$language ${dark ? 'dark' : 'light'} resident and history pages fit 320dp / 160%',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final task = SmallTask(
            id: 'r',
            title: 'A long keep-around task title 整理小书桌',
            resident: true,
            startDay: app.today,
          );
          await store.saveTask(task, create: true, today: app.today);
          await store.setResidentRecord('r', app.today, true, today: app.today);
          await store.saveTask(
            SmallTask(id: 't', title: 'One-time task', completedDay: app.today),
            create: true,
          );
          await app.load();
          await tester.pumpWidget(
            shell(
              Scaffold(body: TasksPage(app: app)),
              language: language,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            shell(
              TaskHistoryPage(app: app),
              language: language,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            shell(
              ResidentTaskPage(app: app, id: 'r'),
              language: language,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byKey(const Key('task-management')),
            180,
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(language == 'zh' ? '更多操作' : 'More actions'),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text(language == 'zh' ? '删除' : 'Delete'),
            180,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(language == 'zh' ? '删除' : 'Delete'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(language == 'zh' ? '取消' : 'Cancel'));
          await tester.pumpAndSettle();
          expect(app.tasks.length, 2);
          expect(app.taskEntries.length, 1);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
