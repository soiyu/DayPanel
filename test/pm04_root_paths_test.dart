import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/widget_platform.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/habit_break.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/home.dart';
import 'package:daypanel/presentation/habits.dart';
import 'package:daypanel/presentation/home_widgets.dart';
import 'package:daypanel/presentation/rest_days.dart';
import 'package:daypanel/presentation/theme.dart';
import 'home_widgets_test.dart' show FakeWidgets;

class PinWidgets extends FakeWidgets implements WidgetPinning {
  bool supported = true;
  final pins = <(String, String, int)>[];
  @override
  Future<bool> canPin() async => supported;
  @override
  Future<bool> hasWidgets() async => false;
  @override
  Future<bool> pin(String kind, String id, int generation) async {
    pins.add((kind, id, generation));
    return true;
  }
}

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late PinWidgets platform;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    platform = PinWidgets();
    app = AppController(
      store,
      clock: () => DateTime(2026, 11, 8),
      widgetPlatform: platform,
    );
    await store.saveHabit(
      Habit(
        id: 'reading',
        title: 'Reading',
        kind: HabitKind.check,
        startDay: app.today.plus(-10),
        weekdays: 1,
      ),
      create: true,
      today: app.today.plus(-10),
    );
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell(Widget child) => MaterialApp(
    locale: const Locale('en'),
    theme: dayPanelTheme(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        150,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(t.element(f));
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets(
    'filter empty state clears filters without adding duplicate habit',
    (t) async {
      app.select(app.today.monday);
      app.filter(context: HabitContext.morning);
      await t.pumpWidget(shell(HomePage(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.text('Clear filters'));
      expect(app.contextFilter, isNull);
      expect(find.byType(HabitTile), findsOneWidget);
      expect((await store.habits()).length, 1);
    },
  );
  testWidgets(
    'unplanned activity can reach selected date and record without changing plan',
    (t) async {
      await t.pumpWidget(shell(HomePage(app: app)));
      await t.pumpAndSettle();
      expect(find.byType(HabitTile), findsNothing);
      await tap(t, find.byKey(const Key('record-other-habit')));
      await tap(t, find.byKey(const Key('extra-habit-reading')));
      expect(find.byType(HabitDetails), findsOneWidget);
      await tap(t, find.byKey(const Key('habit-detail-action-reading')));
      expect((await store.entries()).single.day, app.today);
      expect((await store.habits()).single.weekdays, 1);
    },
  );
  testWidgets('past rest opens day facts instead of today management', (
    t,
  ) async {
    final past = app.today.plus(-3);
    await store.addBreak(
      HabitBreak(
        id: 'rest',
        habitId: 'reading',
        start: past,
        end: past,
        kind: BreakKind.vacation,
      ),
      today: past,
    );
    await app.load();
    app.select(past);
    await t.pumpWidget(shell(HomePage(app: app)));
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('habit-action-reading')));
    expect(find.byType(HabitDetails), findsOneWidget);
    expect(find.byType(RestDaysPage), findsNothing);
    expect(
      find.text(
        'This past break has ended. This day keeps its original rest status.',
      ),
      findsOneWidget,
    );
  });
  testWidgets(
    'pin chooser cancellation sends no request then exact selection requests one',
    (t) async {
      await t.pumpWidget(shell(WidgetsHelpPage(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('pin-widget')));
      await tap(t, find.text('Cancel'));
      expect(platform.pins, isEmpty);
      await tap(t, find.byKey(const Key('pin-widget')));
      await tap(t, find.byKey(const Key('pin-habit-reading')));
      expect(platform.pins, [('habit', 'reading', app.generation)]);
      expect(find.byKey(const Key('pin-result')), findsOneWidget);
      expect(platform.configs, isEmpty);
    },
  );
  testWidgets('unsupported launcher gives real help without fake add button', (
    t,
  ) async {
    platform.supported = false;
    await t.pumpWidget(shell(WidgetsHelpPage(app: app)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('pin-widget')), findsNothing);
    expect(
      find.textContaining('Your launcher does not support'),
      findsOneWidget,
    );
  });
}
