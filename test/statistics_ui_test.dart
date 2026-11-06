import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/statistics.dart';
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
    app = AppController(store, clock: () => DateTime(2026, 11, 6));
    await store.saveHabit(
      Habit(
        id: 'h',
        title: 'Read 阅读',
        kind: HabitKind.check,
        startDay: app.today.plus(-30),
      ),
      create: true,
    );
    await store.saveHabit(
      Habit(
        id: 'q',
        title: 'Water 饮水',
        kind: HabitKind.quantity,
        startDay: app.today.plus(-30),
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
  Widget shell(Widget child, {String language = 'en', bool dark = false}) =>
      MaterialApp(
        locale: Locale(language),
        theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );
  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'table opening cancel explicit save clear and future dates preserve intended day',
    (tester) async {
      await tester.pumpWidget(shell(StatisticsPage(app: app)));
      await tester.pumpAndSettle();
      final cell = find.byKey(Key('matrix-h-${app.today.plus(-1).key}'));
      await tap(tester, cell);
      expect(app.entries, isEmpty);
      await tap(tester, find.text('Cancel'));
      expect(app.entries, isEmpty);
      await tap(tester, cell);
      await tap(tester, find.byKey(const Key('confirm-habit-record')));
      expect(app.entries.single.day, app.today.plus(-1));
      expect(app.cards, isEmpty);
      await tap(tester, cell);
      await tap(tester, find.byKey(const Key('clear-habit-record')));
      expect(app.entries, isEmpty);
      expect(
        tester
            .widget<InkWell>(
              find.byKey(Key('matrix-h-${app.today.plus(1).key}')),
            )
            .onTap,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'quantity correction applies to selected date and stale sheet rejects restore',
    (tester) async {
      await tester.pumpWidget(shell(StatisticsPage(app: app, habitId: 'q')));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(Key('matrix-q-${app.today.plus(-1).key}')));
      await tester.enterText(
        find.byKey(const Key('quantity-input')),
        '250.001',
      );
      await tap(tester, find.text('Save'));
      expect(app.entries.single.value, 250001);
      expect(app.entries.single.day, app.today.plus(-1));
      await tap(tester, find.byKey(Key('matrix-q-${app.today.plus(-1).key}')));
      final snap = await store.exportSnapshot();
      await app.run(() => store.restoreSnapshot(snap));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('quantity-input')), '999');
      await tap(tester, find.text('Save'));
      expect(app.entries.single.value, 250001);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'annual overview selects month and actual calendar day opens record details',
    (tester) async {
      await store.setRecord('h', app.today, 0, today: app.today);
      await app.load();
      await tester.pumpWidget(shell(StatisticsPage(app: app, initialTab: 2)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(Key('calendar-${app.today.key}')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(tester, find.byKey(Key('calendar-${app.today.key}')));
      expect(find.byType(DayHistoryPage), findsOneWidget);
      expect(find.text('Read 阅读'), findsOneWidget);
      await tap(tester, find.text('Read 阅读'));
      expect(find.text('Not completed'), findsWidgets);
      await tap(tester, find.text('Cancel'));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'timeline type filtering and note edit change saved content, empty month is explicit',
    (tester) async {
      await store.saveNote(
        Note(id: 'n', body: 'Remember this day', day: app.today),
        create: true,
        today: app.today,
      );
      await store.saveTask(
        SmallTask(id: 't', title: 'Return book', completedDay: app.today),
        create: true,
      );
      await app.load();
      await tester.pumpWidget(shell(StatisticsPage(app: app, initialTab: 3)));
      await tester.pumpAndSettle();
      await tap(tester, find.text('Journal'));
      await tester.scrollUntilVisible(
        find.text('Remember this day'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Return book'), findsNothing);
      await tap(tester, find.text('Remember this day'));
      await tester.enterText(
        find.byKey(const Key('entry-title')),
        'Edited memory',
      );
      await tap(tester, find.byKey(const Key('save-entry')));
      expect(app.notes.single.body, 'Edited memory');
      await tester.scrollUntilVisible(
        find.byKey(const Key('period-previous')),
        -180,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(tester, find.byKey(const Key('period-previous')));
      await tester.scrollUntilVisible(
        find.text('No records for this selection'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No records for this selection'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('archived matrix remains visible but writes are disabled', (
    tester,
  ) async {
    await store.setArchived('h', true, today: app.today);
    await app.load();
    await tester.pumpWidget(shell(StatisticsPage(app: app, habitId: 'h')));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(Key('matrix-h-${app.today.key}')));
    expect(find.byKey(const Key('confirm-habit-record')), findsNothing);
    expect(
      find.text('Unarchive this habit before correcting records.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('leap day is real and future calendar cells are disabled', (
    tester,
  ) async {
    Day? picked;
    await tester.pumpWidget(
      shell(
        Scaffold(
          body: MonthRecordGrid(
            year: 2024,
            month: 2,
            today: Day.parse('2024-02-28'),
            counts: const {},
            onDay: (d) => picked = d,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-2024-02-29')), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('calendar-2024-02-29')))
          .onTap,
      isNull,
    );
    expect(find.byKey(const Key('calendar-2024-02-30')), findsNothing);
    await tap(tester, find.byKey(const Key('calendar-2024-02-28')));
    expect(picked, Day.parse('2024-02-28'));
    await tester.pumpWidget(const SizedBox());
  });
  for (final language in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$language ${dark ? 'dark' : 'light'} statistics table calendar timeline and quantity keyboard fit 320dp 160%',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await store.setRecord(
            'q',
            app.today.plus(-1),
            2000000,
            today: app.today,
          );
          await store.saveNote(
            Note(id: 'n', body: 'A long memory 记录一个很长的生活片段', day: app.today),
            create: true,
            today: app.today,
          );
          await app.load();
          for (var tab = 0; tab < 4; tab++) {
            await tester.pumpWidget(
              shell(
                StatisticsPage(
                  key: ValueKey(tab),
                  app: app,
                  habitId: 'q',
                  initialTab: tab,
                ),
                language: language,
                dark: dark,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (var i = 0; i < 5; i++) {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -280),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          }
          await tester.pumpWidget(
            shell(
              Scaffold(
                body: Builder(
                  builder: (ctx) => TextButton(
                    onPressed: () => correctRecord(
                      ctx,
                      app,
                      app.habits.firstWhere((h) => h.id == 'q'),
                      app.today,
                    ),
                    child: const Text('Correct'),
                  ),
                ),
              ),
              language: language,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          await tap(tester, find.text('Correct'));
          await tester.enterText(
            find.byKey(const Key('quantity-input')),
            '10.005',
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tap(tester, find.text(language == 'en' ? 'Save' : '保存'));
          expect(
            app.value(app.habits.firstWhere((h) => h.id == 'q'), app.today),
            10005,
          );
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
