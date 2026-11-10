import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/components.dart';
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/habits.dart';
import 'package:daypanel/presentation/home.dart';
import 'package:daypanel/presentation/rest_days.dart';
import 'package:daypanel/presentation/tasks.dart';
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
    app = AppController(store, clock: () => DateTime(2026, 11, 10, 12));
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
  AppLocalizations s(WidgetTester t) =>
      AppLocalizations.of(t.element(find.byType(Scaffold).last));
  MaterialLocalizations m(WidgetTester t) =>
      MaterialLocalizations.of(t.element(find.byType(Scaffold).last));
  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        220,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 35,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .5);
    await t.pumpAndSettle();
    expect(f.hitTestable(), findsOneWidget);
    await t.tap(f);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Future<void> enter(WidgetTester t, Finder f, String text) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        220,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 35,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .4);
    await t.pumpAndSettle();
    await t.enterText(f, text);
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
  }

  Future<void> back(WidgetTester t) async {
    await tap(t, find.byTooltip(m(t).backButtonTooltip));
  }

  Future<void> habit(
    String id, {
    HabitContext context = HabitContext.anytime,
    String? group,
  }) async {
    await store.saveHabit(
      Habit(
        id: id,
        title: id,
        kind: HabitKind.check,
        startDay: app.today,
        context: context,
        groupId: group,
      ),
      create: true,
      today: app.today,
    );
  }

  Future<void> pickerInput(WidgetTester t, DateTime date) async {
    final locale = MaterialLocalizations.of(
      t.element(find.byType(DatePickerDialog)),
    );
    await tap(t, find.byTooltip(locale.inputDateModeButtonLabel));
    await enter(
      t,
      find.byType(TextFormField).last,
      locale.formatCompactDate(date),
    );
    await tap(t, find.text(locale.okButtonLabel).last);
    expect(find.byType(DatePickerDialog), findsNothing);
  }

  Future<void> rangeInput(
    WidgetTester t,
    DateTime from,
    DateTime to, {
    bool cancel = false,
  }) async {
    final local = MaterialLocalizations.of(
      t.element(find.byType(DateRangePickerDialog)),
    );
    await tap(t, find.byTooltip(local.inputDateModeButtonLabel));
    final fields = find.descendant(
      of: find.byType(DateRangePickerDialog),
      matching: find.byType(TextField),
    );
    expect(fields, findsNWidgets(2));
    await enter(t, fields.at(0), local.formatCompactDate(from));
    await enter(t, fields.at(1), local.formatCompactDate(to));
    await tap(
      t,
      find.text(cancel ? local.cancelButtonLabel : local.okButtonLabel).last,
    );
    expect(find.byType(DateRangePickerDialog), findsNothing);
  }

  Future<void> openTaskEdit(WidgetTester t, String title) async {
    await tap(t, find.text(title));
    await tap(t, find.byTooltip(s(t).edit));
    expect(find.byType(EntryEditor), findsOneWidget);
  }

  Future<void> createTask(
    WidgetTester t,
    String title, {
    bool resident = false,
  }) async {
    await tap(t, find.byKey(const Key('add-entry')));
    await enter(t, find.byKey(const Key('entry-title')), title);
    if (resident) {
      await tap(t, find.text(s(t).residentTask));
    }
    await tap(t, find.byKey(const Key('save-entry')));
  }

  for (final language in ['zh', 'en']) {
    testWidgets(
      'QA02 E02 $language edit context and group then apply both real filter controls',
      (t) async {
        await store.saveGroup(
          const HabitGroup(id: 'a', name: 'Group A'),
          create: true,
        );
        await store.saveGroup(
          const HabitGroup(id: 'b', name: 'Group B'),
          create: true,
        );
        await habit('Target');
        await habit(
          'Morning other group',
          context: HabitContext.morning,
          group: 'b',
        );
        await habit(
          'Evening same group',
          context: HabitContext.evening,
          group: 'a',
        );
        await app.load();
        await t.pumpWidget(shell(HomePage(app: app), language: language));
        await t.pumpAndSettle();
        await tap(t, find.text('Target'));
        await tap(t, find.byKey(const Key('habit-settings')));
        await tap(t, find.byKey(const Key('edit-habit-settings')));
        await tap(t, find.byKey(const Key('habit-advanced-settings')));
        await tap(t, find.text(s(t).morning));
        await tap(t, find.text('Group A'));
        await tap(t, find.byKey(const Key('save-entry')));
        expect(
          app.habits.firstWhere((h) => h.id == 'Target').context,
          HabitContext.morning,
        );
        expect(app.habits.firstWhere((h) => h.id == 'Target').groupId, 'a');
        await back(t);
        await back(t);
        await tap(t, find.byKey(const Key('daily-filter')));
        await tap(t, find.text(s(t).morning));
        await tap(t, find.text('Group A'));
        await tap(t, find.text(s(t).applyFilter));
        expect(find.byKey(const Key('habit-card-Target')), findsOneWidget);
        expect(
          find.byKey(const Key('habit-card-Morning other group')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('habit-card-Evening same group')),
          findsNothing,
        );
        expect(find.text(s(t).allHabitsProgress), findsOneWidget);
        expect(app.allDailyPlanned.length, 3);
        expect(app.planned.single.id, 'Target');
        await tap(t, find.byKey(const Key('daily-filter')));
        await tap(t, find.text(s(t).resetFilter));
        expect(app.planned.length, 3);
        expect(app.entries, isEmpty);
        await t.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'QA02 E04 ordering arrows and drag have explicit save and back cancellation',
    (t) async {
      await habit('First');
      await habit('Second');
      await habit('Third');
      await app.load();
      await t.pumpWidget(shell(HabitLibrary(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.text(s(t).sortHabits));
      await tap(t, find.byTooltip(s(t).moveDown).first);
      expect(
        t.getTopLeft(find.text('Second')).dy,
        lessThan(t.getTopLeft(find.text('First')).dy),
      );
      await back(t);
      expect(app.habits.map((h) => h.id).toList(), [
        'First',
        'Second',
        'Third',
      ]);
      await tap(t, find.text(s(t).sortHabits));
      await tap(t, find.byTooltip(s(t).moveDown).first);
      await tap(t, find.text(s(t).save));
      expect(app.habits.map((h) => h.id).toList(), [
        'Second',
        'First',
        'Third',
      ]);
      await tap(t, find.text(s(t).sortHabits));
      final handles = find.byType(ReorderableDragStartListener);
      expect(handles, findsNWidgets(3));
      final start = t.getCenter(handles.at(2));
      final finish = Offset(
        start.dx,
        t.getTopLeft(find.byType(ReorderableListView)).dy + 4,
      );
      final gesture = await t.startGesture(start);
      await t.pump(const Duration(milliseconds: 200));
      for (var step = 1; step <= 16; step++) {
        await gesture.moveTo(Offset.lerp(start, finish, step / 16)!);
        await t.pump(const Duration(milliseconds: 50));
      }
      await t.pumpAndSettle();
      await gesture.up();
      await t.pumpAndSettle();
      expect(
        t.getTopLeft(find.text('Third')).dy,
        lessThan(t.getTopLeft(find.text('Second')).dy),
      );
      await tap(t, find.text(s(t).save));
      expect(app.habits.map((h) => h.id).toList(), [
        'Third',
        'Second',
        'First',
      ]);
      expect(app.entries, isEmpty);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA02 F04 real date-range picker creates future vacation, cancellation writes nothing, explicit removal clears only future break',
    (t) async {
      await habit('Rest tester');
      await app.load();
      await t.pumpWidget(shell(RestDaysPage(app: app, id: 'Rest tester')));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('vacation-habit')));
      await rangeInput(
        t,
        app.today.plus(1).date,
        app.today.plus(3).date,
        cancel: true,
      );
      expect(await store.breaks(), isEmpty);
      await tap(t, find.byKey(const Key('vacation-habit')));
      await rangeInput(t, app.today.plus(1).date, app.today.plus(3).date);
      expect(app.rests.single.start, app.today.plus(1));
      expect(app.rests.single.end, app.today.plus(3));
      expect(app.restOn(app.habits.single, app.today), isNull);
      expect(app.restOn(app.habits.single, app.today.plus(1)), isNotNull);
      await tap(t, find.byKey(Key('end-rest-${app.rests.single.id}')));
      expect(await store.breaks(), isEmpty);
      expect(app.entries, isEmpty);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA02 F05 real date-range overlap and excessive span show feedback without changing saved vacation',
    (t) async {
      await habit('Rest tester');
      await app.load();
      await t.pumpWidget(shell(RestDaysPage(app: app, id: 'Rest tester')));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('vacation-habit')));
      await rangeInput(t, app.today.plus(1).date, app.today.plus(3).date);
      final before = (await store.exportSnapshot()).tables;
      await tap(t, find.byKey(const Key('vacation-habit')));
      await rangeInput(t, app.today.plus(2).date, app.today.plus(4).date);
      expect(find.text(s(t).restConflict), findsOneWidget);
      expect((await store.exportSnapshot()).tables, before);
      await tap(t, find.byKey(const Key('vacation-habit')));
      await rangeInput(t, app.today.plus(1).date, app.today.plus(366).date);
      expect(find.text(s(t).restRangeLimit), findsWidgets);
      expect((await store.exportSnapshot()).tables, before);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA02 G02 actual task date picker moves one-time task between today future overdue and no-date groups',
    (t) async {
      await t.pumpWidget(shell(HomePage(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('tab-1')));
      await createTask(t, 'Return book');
      expect(find.text(s(t).inbox), findsOneWidget);
      for (final step in [(0, 'today'), (1, 'upcoming'), (-1, 'overdue')]) {
        await openTaskEdit(t, 'Return book');
        await tap(t, find.text(s(t).chooseDate));
        await pickerInput(t, app.today.plus(step.$1).date);
        await tap(t, find.byKey(const Key('save-entry')));
        await back(t);
        expect(app.tasks.single.dueDay, app.today.plus(step.$1));
        final group = step.$2 == 'today'
            ? s(t).todayLabel
            : step.$2 == 'upcoming'
            ? s(t).upcoming
            : s(t).overdue;
        expect(
          find.descendant(
            of: find.byType(SectionTitle),
            matching: find.text(group),
          ),
          findsOneWidget,
        );
        expect(app.tasks.single.completedDay, isNull);
      }
      await openTaskEdit(t, 'Return book');
      await tap(t, find.text(s(t).noDate));
      await tap(t, find.byKey(const Key('save-entry')));
      await back(t);
      expect(app.tasks.single.dueDay, isNull);
      expect(find.text(s(t).inbox), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA02 G04 real history date selection and titles open correct one-time and resident details',
    (t) async {
      await t.pumpWidget(shell(HomePage(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('tab-1')));
      await createTask(t, 'Return book');
      await createTask(t, 'Tidy table', resident: true);
      for (final task in List<SmallTask>.from(app.tasks)) {
        await tap(t, find.byKey(Key('task-action-${task.id}')));
      }
      await tap(t, find.byKey(const Key('task-history')));
      final label = m(t).formatMediumDate(app.today.date);
      await tap(t, find.widgetWithText(TextButton, label));
      await pickerInput(t, app.today.date);
      expect(find.text('Return book'), findsOneWidget);
      expect(find.text('Tidy table'), findsOneWidget);
      await tap(t, find.text('Return book'));
      expect(find.byType(OneTimeTaskPage), findsOneWidget);
      expect(app.tasks.firstWhere((v) => !v.resident).completedDay, app.today);
      await back(t);
      await tap(t, find.text('Tidy table'));
      expect(find.byType(ResidentTaskPage), findsOneWidget);
      expect(
        t.widget<ResidentTaskPage>(find.byType(ResidentTaskPage)).initialDay,
        app.today,
      );
      expect(app.taskEntries.length, 1);
      await t.pumpWidget(const SizedBox());
    },
  );

  for (final resident in [false, true]) {
    testWidgets(
      'QA02 G10 resident=$resident rename cancel/save and delete cancel/confirm via real menus',
      (t) async {
        await t.pumpWidget(shell(HomePage(app: app)));
        await t.pumpAndSettle();
        await tap(t, find.byKey(const Key('tab-1')));
        await createTask(t, 'Original', resident: resident);
        final id = app.tasks.single.id;
        await tap(t, find.byKey(Key('task-action-$id')));
        final before = (await store.exportSnapshot()).tables;
        await tap(t, find.byTooltip(s(t).more));
        await tap(t, find.text(s(t).edit));
        await enter(t, find.byKey(const Key('entry-title')), 'Discard rename');
        await tap(t, find.text(s(t).cancel).last);
        expect((await store.exportSnapshot()).tables, before);
        await tap(t, find.byTooltip(s(t).more));
        await tap(t, find.text(s(t).edit));
        await enter(t, find.byKey(const Key('entry-title')), 'Saved rename');
        await tap(t, find.byKey(const Key('save-entry')));
        expect(app.tasks.single.title, 'Saved rename');
        expect(app.taskDoneOn(app.tasks.single, app.today), isTrue);
        await tap(t, find.byTooltip(s(t).more));
        await tap(t, find.text(s(t).delete));
        await tap(t, find.text(s(t).cancel).last);
        expect(app.tasks.single.id, id);
        await tap(t, find.byTooltip(s(t).more));
        await tap(t, find.text(s(t).delete));
        await tap(t, find.text(s(t).delete).last);
        expect(app.tasks, isEmpty);
        expect(app.taskEntries, isEmpty);
        expect(app.entries, isEmpty);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
