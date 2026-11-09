import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/components.dart';
import 'package:daypanel/presentation/habits.dart';
import 'package:daypanel/presentation/home.dart';
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
      clock: () => DateTime(2026, 11, 9),
      widgetPlatform: platform,
    );
    await store.saveHabit(
      Habit(
        id: 'h',
        title: 'Stretch',
        kind: HabitKind.check,
        startDay: app.today,
      ),
      create: true,
      today: app.today,
    );
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell(Widget child, {String language = 'en'}) => MaterialApp(
    locale: Locale(language),
    theme: dayPanelTheme(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  Widget origin(Widget destination) => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => destination),
        ),
        child: const Text('Open source'),
      ),
    ),
  );
  Future<void> tap(WidgetTester t, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        finder,
        250,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(t.element(finder), alignment: .5);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  Future<void> requestDelete(WidgetTester t) async {
    await tap(t, find.text('Delete').last);
    expect(find.textContaining('Delete this habit'), findsOneWidget);
  }

  Future<void> confirmDelete(WidgetTester t) async {
    await requestDelete(t);
    await tap(t, find.text('Delete').last);
  }

  testWidgets(
    'daily detail settings deletion returns to daily without an unavailable page',
    (t) async {
      await t.pumpWidget(shell(HomePage(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.text('Stretch'));
      await tap(t, find.byKey(const Key('habit-settings')));
      await confirmDelete(t);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(HabitDetails), findsNothing);
      expect(find.byType(HabitManagementPage), findsNothing);
      expect(find.byType(HabitUnavailable), findsNothing);
      expect(await store.habits(), isEmpty);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'management-list deletion returns exactly to the library and keeps other habits',
    (t) async {
      await store.saveHabit(
        Habit(
          id: 'other',
          title: 'Reading',
          kind: HabitKind.check,
          startDay: app.today,
        ),
        create: true,
        today: app.today,
      );
      await app.load();
      await t.pumpWidget(shell(origin(HabitLibrary(app: app))));
      await t.pumpAndSettle();
      await tap(t, find.text('Open source'));
      await tap(t, find.text('Stretch'));
      await confirmDelete(t);
      expect(find.byType(HabitLibrary), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Open source'), findsNothing);
      expect((await store.habits()).single.id, 'other');
    },
  );
  testWidgets('last library item deletion shows the ordinary empty library', (
    t,
  ) async {
    await t.pumpWidget(shell(origin(HabitLibrary(app: app))));
    await t.pumpAndSettle();
    await tap(t, find.text('Open source'));
    await tap(t, find.text('Stretch'));
    await confirmDelete(t);
    expect(find.byType(HabitLibrary), findsOneWidget);
    expect(find.byType(HabitUnavailable), findsNothing);
    expect(find.byType(EmptyState), findsOneWidget);
  });
  testWidgets(
    'newly created detail deletion returns to its actual creation source',
    (t) async {
      await t.pumpWidget(shell(HomePage(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('add-entry')));
      await tap(t, find.byKey(const Key('custom-habit')));
      await t.enterText(find.byKey(const Key('entry-title')), 'Temporary');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('save-entry')));
      expect(find.byType(HabitDetails), findsOneWidget);
      await tap(t, find.byKey(const Key('habit-settings')));
      await confirmDelete(t);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(HabitUnavailable), findsNothing);
      expect((await store.habits()).single.id, 'h');
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'widget detail deletion closes its isolated flow back to the launcher',
    (t) async {
      await t.pumpWidget(
        shell(
          WidgetFlow(
            app: app,
            request: {
              'mode': 'view',
              'widgetId': 3,
              'kind': 'habit',
              'id': 'h',
              'generation': app.generation,
              'day': app.today.key,
              'token': 'fixture',
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(HabitDetails), findsOneWidget);
      await tap(t, find.byKey(const Key('habit-settings')));
      await confirmDelete(t);
      expect(platform.closes, 1);
      expect(find.byType(HabitDetails), findsNothing);
      expect(find.byType(HabitUnavailable), findsNothing);
    },
  );
  testWidgets(
    'deletion cancellation does not unwind the route or remove the habit',
    (t) async {
      await t.pumpWidget(shell(origin(HabitDetails(app: app, id: 'h'))));
      await t.pumpAndSettle();
      await tap(t, find.text('Open source'));
      await tap(t, find.byKey(const Key('habit-settings')));
      await requestDelete(t);
      await tap(t, find.text('Cancel'));
      expect(find.byType(HabitManagementPage), findsOneWidget);
      expect((await store.habits()).single.id, 'h');
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.byType(HabitDetails), findsOneWidget);
    },
  );
  testWidgets(
    'failed deletion remains on settings and exposes retryable storage feedback',
    (t) async {
      await store.db.execute(
        "CREATE TRIGGER deny_test_delete BEFORE DELETE ON habits BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await t.pumpWidget(shell(origin(HabitDetails(app: app, id: 'h'))));
      await t.pumpAndSettle();
      await tap(t, find.text('Open source'));
      await tap(t, find.byKey(const Key('habit-settings')));
      await confirmDelete(t);
      expect(find.byType(HabitManagementPage), findsOneWidget);
      expect((await store.habits()).single.id, 'h');
      final local = AppLocalizations.of(
        t.element(find.byType(HabitManagementPage)),
      );
      await t.scrollUntilVisible(
        find.text(local.storageError),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      expect(find.text(local.storageError), findsOneWidget);
    },
  );
  for (final language in ['zh', 'en']) {
    for (final size in [const Size(320, 568), const Size(414, 921)]) {
      testWidgets(
        '$language missing habit stays centered and padded at $size with 160 percent text',
        (t) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          await t.pumpWidget(
            shell(
              origin(HabitDetails(app: app, id: 'h')),
              language: language,
            ),
          );
          await t.pumpAndSettle();
          await tap(t, find.text('Open source'));
          await app.run(() => store.remove('habits', 'h'));
          await t.pumpAndSettle();
          final empty = find.byKey(const Key('habit-unavailable'));
          final rect = t.getRect(empty);
          expect(rect.left, 20);
          expect(rect.width, size.width - 40);
          final local = AppLocalizations.of(t.element(empty));
          for (final text in [local.habitUnavailable, local.reopenContext]) {
            final bounds = t.getRect(find.text(text));
            expect(bounds.center.dx, closeTo(size.width / 2, .1));
            expect(bounds.left, greaterThanOrEqualTo(20));
            expect(bounds.right, lessThanOrEqualTo(size.width - 20));
          }
          final action = find.descendant(
            of: empty,
            matching: find.byType(AppAction),
          );
          expect(t.widget<AppAction>(action).icon, Icons.arrow_back_rounded);
          expect(t.takeException(), isNull);
          await tap(t, action);
          expect(find.text('Open source'), findsOneWidget);
        },
      );
    }
  }
}
