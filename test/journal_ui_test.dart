import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/habits.dart';
import 'package:daypanel/presentation/journal.dart';
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
    app = AppController(store, clock: () => DateTime(2026, 11, 6, 12));
    await store.saveHabit(
      Habit(
        id: 'h',
        title: 'Read a few pages',
        kind: HabitKind.check,
        startDay: app.today.plus(-20),
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
  Widget launcher({Note? note, String language = 'en', bool dark = false}) =>
      shell(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openEditor(context, app, 'note', note: note),
              child: const Text('Launch'),
            ),
          ),
        ),
        language: language,
        dark: dark,
      );
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'detail creates dated linked journal without completing habit and opens all logs',
    (tester) async {
      await tester.pumpWidget(shell(HabitDetails(app: app, id: 'h')));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('add-habit-note')));
      expect(find.text('Nov 6, 2026'), findsOneWidget);
      expect(find.text('Read a few pages').last, findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('entry-title')),
        'Chapter one felt peaceful',
      );
      await tap(tester, find.byKey(const Key('save-entry')));
      expect(app.notes.single.habitId, 'h');
      expect(app.notes.single.day, app.today);
      expect(app.entries, isEmpty);
      await tap(tester, find.text('All related notes'));
      expect(find.text('Chapter one felt peaceful'), findsOneWidget);
      await tap(tester, find.text('Chapter one felt peaceful'));
      await tester.enterText(
        find.byKey(const Key('entry-title')),
        'Chapter two',
      );
      await tap(tester, find.byKey(const Key('save-entry')));
      expect(app.notes.single.body, 'Chapter two');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'editor changes date and association; cancel and system back do not write',
    (tester) async {
      await tester.pumpWidget(launcher());
      await tester.pumpAndSettle();
      await tap(tester, find.text('Launch'));
      await tap(tester, find.byKey(const Key('note-date')));
      await tap(tester, find.text('5').last);
      await tap(tester, find.text('OK'));
      await tap(tester, find.byKey(const Key('note-habit')));
      await tap(tester, find.text('Read a few pages'));
      await tester.enterText(
        find.byKey(const Key('entry-title')),
        'Yesterday reading',
      );
      await tap(tester, find.byKey(const Key('save-entry')));
      expect(app.notes.single.day, app.today.plus(-1));
      expect(app.notes.single.habitId, 'h');
      final saved = app.notes.single;
      await tester.pumpWidget(launcher(note: saved));
      await tester.pumpAndSettle();
      await tap(tester, find.text('Launch'));
      await tap(tester, find.byKey(const Key('note-habit')));
      await tap(tester, find.text('Independent notes'));
      await tester.enterText(find.byKey(const Key('entry-title')), 'Not saved');
      await tap(tester, find.text('Cancel'));
      expect(app.notes.single.body, 'Yesterday reading');
      expect(app.notes.single.habitId, 'h');
      await tap(tester, find.text('Launch'));
      await tester.enterText(
        find.byKey(const Key('entry-title')),
        'Back discards',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect((await store.notes()).single.body, saved.body);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'month navigation search and habit picker combine, date cancel does not filter',
    (tester) async {
      await store.saveNote(
        Note(id: 'a', body: 'Tea this month', day: app.today, habitId: 'h'),
        create: true,
      );
      await store.saveNote(
        Note(id: 'b', body: 'Tea in October', day: Day.parse('2026-10-31')),
        create: true,
      );
      await app.load();
      await tester.pumpWidget(shell(Scaffold(body: JournalPage(app: app))));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('note-search')), 'tea');
      await tester.pumpAndSettle();
      expect(app.visibleNotes.single.id, 'a');
      await tap(tester, find.byKey(const Key('previous-month')));
      expect(app.visibleNotes.single.id, 'b');
      await tap(tester, find.byKey(const Key('note-filter')));
      await tap(tester, find.text('Read a few pages'));
      expect(app.visibleNotes, isEmpty);
      await tester.scrollUntilVisible(
        find.text('No matching notes'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No matching notes'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('All months'),
        -180,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(tester, find.text('All months'));
      expect(app.visibleNotes.single.id, 'a');
      await tap(tester, find.byKey(const Key('locate-note-date')));
      await tap(tester, find.text('Cancel'));
      expect(app.journalQuery.day, isNull);
      await tap(tester, find.byKey(const Key('locate-note-date')));
      await tap(tester, find.text('5').last);
      await tap(tester, find.text('OK'));
      expect(app.journalQuery.day, app.today.plus(-1));
      expect(app.visibleNotes, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'delete confirmation cancellation keeps note; confirmation removes only note',
    (tester) async {
      await store.saveNote(
        Note(
          id: 'n',
          body: 'Delete only this text',
          day: app.today,
          habitId: 'h',
        ),
        create: true,
      );
      await app.load();
      await tester.pumpWidget(shell(HabitJournalPage(app: app, habitId: 'h')));
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('More actions'));
      await tap(tester, find.text('Delete').last);
      await tap(tester, find.text('Cancel'));
      expect(app.notes.length, 1);
      await tap(tester, find.byTooltip('More actions'));
      await tap(tester, find.text('Delete').last);
      await tap(tester, find.text('Delete').last);
      expect(app.notes, isEmpty);
      expect(app.habits.length, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('restored generation rejects an open editor', (tester) async {
    await store.saveNote(
      Note(id: 'n', body: 'Original', day: app.today),
      create: true,
    );
    await app.load();
    final note = app.notes.single;
    final snapshot = await store.exportSnapshot();
    await tester.pumpWidget(launcher(note: note));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Launch'));
    await tester.enterText(find.byKey(const Key('entry-title')), 'Stale words');
    await app.run(() => store.restoreSnapshot(snapshot));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const Key('save-entry')));
    expect((await store.notes()).single.body, 'Original');
    expect(find.byKey(const Key('save-entry')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'habit deletion opened before restore cannot detach restored journal',
    (tester) async {
      await store.saveNote(
        Note(id: 'n', body: 'Restored journal', day: app.today, habitId: 'h'),
        create: true,
      );
      await app.load();
      final snapshot = await store.exportSnapshot();
      await tester.pumpWidget(shell(HabitDetails(app: app, id: 'h')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Delete'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(tester, find.text('Delete'));
      await app.run(() => store.restoreSnapshot(snapshot));
      await tester.pumpAndSettle();
      await tap(tester, find.text('Delete').last);
      expect(app.habits.single.id, 'h');
      expect(app.notes.single.habitId, 'h');
      expect(app.error, isNotNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final language in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$language ${dark ? 'dark' : 'light'} journal search filters and editor fit narrow large text keyboard',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(
            shell(
              Scaffold(body: JournalPage(app: app)),
              language: language,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.enterText(
            find.byKey(const Key('note-search')),
            'no matching text',
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text(language == 'en' ? 'No matching notes' : '没有符合条件的手记'),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(launcher(language: language, dark: dark));
          await tester.pumpAndSettle();
          await tap(tester, find.text('Launch'));
          expect(tester.takeException(), isNull);
          await tap(tester, find.byKey(const Key('note-habit')));
          expect(tester.takeException(), isNull);
          await tap(tester, find.text('Read a few pages'));
          await tester.enterText(
            find.byKey(const Key('entry-title')),
            'Layout note',
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('save-entry')).hitTestable(),
            findsOneWidget,
          );
          await tap(tester, find.byKey(const Key('save-entry')));
          expect(app.notes.single.body, 'Layout note');
          expect(app.notes.single.habitId, 'h');
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
