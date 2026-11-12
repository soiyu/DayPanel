import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/widget_platform.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/achievements.dart';
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/habit_icon.dart';
import 'package:daypanel/presentation/habits.dart';
import 'package:daypanel/presentation/home_widgets.dart';
import 'package:daypanel/presentation/theme.dart';

class TestWidgetPinning implements WidgetPlatform, WidgetPinning {
  bool pinResult = true;
  @override
  Future<bool> canPin() async => true;
  @override
  Future<bool> hasWidgets() async => true;
  @override
  Future<bool> pin(String kind, String id, int generation) async => pinResult;
  @override
  Future<void> refresh() async {}
  @override
  Future<Map<String, Object?>?> launch() async => null;
  @override
  Future<bool> validate(Map<String, Object?> request) async => true;
  @override
  Future<void> configure(int widgetId, String id, int generation) async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> openApp() async {}
}

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late TestWidgetPinning platform;
  final today = Day(DateTime(2026, 11, 12));

  setUp(() async {
    platform = TestWidgetPinning();
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(
      store,
      widgetPlatform: platform,
      clock: () => today.date,
    );
    await app.load();
  });

  tearDown(() async {
    app.dispose();
    await store.close();
  });

  Widget shell(Widget child, {String locale = 'zh'}) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: dayPanelTheme(Brightness.light),
    home: Scaffold(body: child),
  );

  testWidgets('Inline quick increment records without opening a new page', (
    tester,
  ) async {
    final habit = Habit(
      id: 'water-habit',
      title: '喝水',
      kind: HabitKind.quantity,
      target: 1500000, // 1500 ml
      unit: 'ml',
      startDay: today,
    );
    await store.saveHabit(habit, create: true);
    await app.load();

    await tester.pumpWidget(
      shell(HabitTile(app: app, habit: habit, day: today)),
    );
    await tester.pumpAndSettle();

    // Verify quick add button exists on tile with +250ml
    final quickAddFinder = find.byKey(Key('habit-quick-add-${habit.id}'));
    expect(quickAddFinder, findsOneWidget);
    expect(find.text('+250ml'), findsOneWidget);

    // Tap quick add directly on the card
    await tester.tap(quickAddFinder);
    await tester.pumpAndSettle();

    // Verify no bottom sheet opened and value is recorded directly!
    expect(find.byType(QuantityEditor), findsNothing);
    expect(app.value(habit, today), 250000);

    // Tap habit icon to trigger another quick add
    final iconFinder = find.byType(HabitIcon).first;
    await tester.tap(iconFinder);
    await tester.pumpAndSettle();
    expect(app.value(habit, today), 500000);

    // Tap edit button to open QuantityEditor
    final editFinder = find.byKey(Key('habit-action-${habit.id}'));
    await tester.tap(editFinder);
    await tester.pumpAndSettle();
    expect(find.byType(QuantityEditor), findsOneWidget);
  });

  testWidgets('Count habits quick increment adds 1 count', (tester) async {
    final habit = Habit(
      id: 'pushup-habit',
      title: '俯卧撑',
      kind: HabitKind.count,
      target: 3000, // 3 times
      unit: '次',
      startDay: today,
    );
    await store.saveHabit(habit, create: true);
    await app.load();

    await tester.pumpWidget(
      shell(HabitTile(app: app, habit: habit, day: today)),
    );
    await tester.pumpAndSettle();

    final quickAddFinder = find.byKey(Key('habit-quick-add-${habit.id}'));
    expect(quickAddFinder, findsOneWidget);
    expect(find.text('+1'), findsOneWidget);

    await tester.tap(quickAddFinder);
    await tester.pumpAndSettle();

    expect(app.value(habit, today), 1000);
  });

  testWidgets('Card collection displays milestone progress', (tester) async {
    final habit = Habit(
      id: 'habit-1',
      title: '晨读',
      kind: HabitKind.check,
      target: 1000,
      unit: '',
      startDay: today,
    );
    await store.saveHabit(habit, create: true);
    await app.load();
    await app.recordHabit(habit, today, 1000, app.generation);
    await app.store.claimCard(today, today: today);
    await app.load();

    await tester.pumpWidget(shell(CardCollection(app: app)));
    await tester.pumpAndSettle();

    // Next milestone is Day 7
    expect(find.textContaining('下一里程碑'), findsOneWidget);
    expect(find.textContaining('初始之火'), findsOneWidget);
    expect(find.text('1 / 7'), findsOneWidget);
  });

  testWidgets('WidgetsHelpPage shows troubleshoot note after pin request', (
    tester,
  ) async {
    final habit = Habit(
      id: 'h1',
      title: '喝水',
      kind: HabitKind.check,
      target: 1000,
      unit: '',
      startDay: today,
    );
    await store.saveHabit(habit, create: true);
    await app.load();

    await tester.pumpWidget(shell(WidgetsHelpPage(app: app)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pin-widget')));
    await tester.pumpAndSettle();

    // Select habit in sheet
    await tester.tap(find.byKey(Key('pin-habit-${habit.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pin-result')), findsOneWidget);
    expect(find.textContaining('桌面快捷方式'), findsOneWidget);
  });
}
