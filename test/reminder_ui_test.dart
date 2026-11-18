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
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/tasks.dart';
import 'package:daypanel/presentation/plus_page.dart';
import 'package:daypanel/data/reminder_platform.dart';
import 'package:daypanel/data/plus_access.dart';
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

  testWidgets('task reminder can be configured in ReminderEditor and saved', (
    tester,
  ) async {
    final task = SmallTask(id: 't1', title: 'Buy milk', resident: false);
    await store.saveTask(task, create: true, today: app.today);
    await app.load();

    await tester.pumpWidget(shell(ReminderEditor(app: app, task: task)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enable reminder'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-reminder')));
    await tester.pumpAndSettle();

    expect((await store.taskReminders()).single.enabled, isTrue);
    expect((await store.taskReminders()).single.taskId, 't1');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'EntryEditor allows configuring reminder directly for habit and task',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Habit with reminder
      await tester.pumpWidget(shell(EntryEditor(app: app, type: 'habit')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Exercise');
      await tester.tap(find.text('Every day'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enable reminder'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-entry')));
      await tester.pumpAndSettle();

      expect(app.habits.any((h) => h.title == 'Exercise'), isTrue);
      final habitId = app.habits.firstWhere((h) => h.title == 'Exercise').id;
      expect(app.reminderFor(habitId).enabled, isTrue);

      await tester.pumpWidget(const SizedBox());

      // 2. Task with reminder
      await tester.pumpWidget(shell(EntryEditor(app: app, type: 'task')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Send email');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enable reminder'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save-entry')));
      await tester.pumpAndSettle();

      expect(app.tasks.any((t) => t.title == 'Send email'), isTrue);
      final taskId = app.tasks.firstWhere((t) => t.title == 'Send email').id;
      expect(app.taskReminderFor(taskId).enabled, isTrue);

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'ResidentTaskPage and OneTimeTaskPage display reminder setting row and open editor',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final residentTask = SmallTask(
        id: 'rt1',
        title: 'Daily walk',
        resident: true,
        startDay: app.today,
      );
      final oneTimeTask = SmallTask(
        id: 'ot1',
        title: 'Pick package',
        resident: false,
        dueDay: app.today,
      );
      await store.saveTask(residentTask, create: true, today: app.today);
      await store.saveTask(oneTimeTask, create: true, today: app.today);
      await app.load();

      // Test ResidentTaskPage
      await tester.pumpWidget(shell(ResidentTaskPage(app: app, id: 'rt1')));
      await tester.pumpAndSettle();

      expect(find.text('Resident Task Reminder'), findsOneWidget);
      await tester.tap(find.text('Resident Task Reminder'));
      await tester.pumpAndSettle();

      expect(find.byType(ReminderEditor), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());

      // Test OneTimeTaskPage
      await tester.pumpWidget(shell(OneTimeTaskPage(app: app, id: 'ot1')));
      await tester.pumpAndSettle();

      expect(find.text('To-do Reminder'), findsOneWidget);
      await tester.tap(find.text('To-do Reminder'));
      await tester.pumpAndSettle();

      expect(find.byType(ReminderEditor), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'sound and vibration toggles require Plus and exact alarm check',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            PlusAccess.channel,
            (call) async => {'owned': false, 'available': true},
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(PlusAccess.channel, null),
      );

      app.plus.testing = false;
      app.plus.owned = false;
      expect(app.plus.enabled, isFalse);

      await tester.pumpWidget(shell(RemindersPage(app: app)));
      await tester.pumpAndSettle();

      // Attempt toggling sound without Plus -> should open PlusPage
      await tester.tap(find.byKey(const Key('reminders-page-sound')));
      await tester.pumpAndSettle();

      expect(find.byType(PlusPage), findsOneWidget);
      expect(app.reminderSound, isFalse);

      // Dismiss PlusPage
      Navigator.pop(tester.element(find.byType(PlusPage)));
      await tester.pumpAndSettle();

      // Now enable Plus, but exact alarm is false
      app.plus.owned = true;
      expect(app.plus.enabled, isTrue);
      app.reminderStatus = const ReminderStatus(
        notifications: true,
        exact: false,
      );

      // Attempt toggling sound -> should prompt exact alarm dialog
      await tester.tap(find.byKey(const Key('reminders-page-sound')));
      await tester.pumpAndSettle();

      expect(find.text('Reminder timing'), findsOneWidget);
      // Cancel exact alarm prompt
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(app.reminderSound, isFalse);

      // Now set exact to true
      app.reminderStatus = const ReminderStatus(
        notifications: true,
        exact: true,
      );
      await tester.tap(find.byKey(const Key('reminders-page-sound')));
      await tester.pumpAndSettle();

      expect(app.reminderSound, isTrue);

      await tester.pumpWidget(const SizedBox());
    },
  );
}
