import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/reminder.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/main.dart';
import 'package:daypanel/presentation/reminders.dart';
import 'package:daypanel/presentation/theme.dart';
import 'reminders_test.dart' show FakeReminderPlatform;

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late FakeReminderPlatform platform;
  late Habit h;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    platform = FakeReminderPlatform();
    app = AppController(
      store,
      clock: () => DateTime(2026, 11, 6),
      reminderPlatform: platform,
    );
    h = Habit(
      id: 'h',
      title: 'A little reading',
      kind: HabitKind.check,
      startDay: app.today,
    );
    await store.saveHabit(h, create: true);
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell(Widget child, {String locale = 'en', bool dark = false}) =>
      MaterialApp(
        locale: Locale(locale),
        theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
  testWidgets(
    'permission asked only on enabled save; denial retains times and cancel does not write',
    (tester) async {
      await tester.pumpWidget(shell(ReminderEditor(app: app, habit: h)));
      await tester.pumpAndSettle();
      expect(platform.requests, 0);
      // The visible label is also the switch's named, tappable surface.
      await tester.tap(find.text('Enable reminder'));
      await tester.pumpAndSettle();
      expect(platform.requests, 0);
      await tester.tap(find.byKey(const Key('save-reminder')));
      await tester.pumpAndSettle();
      expect(platform.requests, 1);
      expect((await store.reminders()).single.enabled, isTrue);
      expect(app.reminderStatus.notifications, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(shell(ReminderEditor(app: app, habit: h)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('enable-reminder')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await store.reminders()).single.enabled, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final language in ['en', 'zh']) {
    testWidgets(
      '$language reminders fit small screen large text in dark mode',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await store.saveReminder(
          HabitReminder(
            habitId: 'h',
            enabled: true,
            minutes: [0, 540, 720, 1200, 1439],
          ),
        );
        await app.load();
        await tester.pumpWidget(
          shell(RemindersPage(app: app), locale: language, dark: true),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          shell(
            ReminderEditor(app: app, habit: h),
            locale: language,
            dark: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('save-reminder')).hitTestable(),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'notification opens quantity entry without writing; stale date is ignored',
    (tester) async {
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
      await app.load();
      platform.open = {
        'id': 'water',
        'day': app.today.key,
        'generation': app.generation,
      };
      await tester.pumpWidget(DayPanelApp(app: app));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quantity-input')), findsOneWidget);
      expect(app.entries, isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      platform.open = {
        'id': 'water',
        'day': app.today.plus(-1).key,
        'generation': app.generation,
      };
      await tester.pumpWidget(DayPanelApp(app: app));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quantity-input')), findsNothing);
      expect(app.entries, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
