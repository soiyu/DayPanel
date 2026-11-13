import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/appearance.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/habits.dart';
import 'package:daypanel/presentation/home.dart';
import 'package:daypanel/presentation/organization.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  setUpAll(() async {
    final font = FontLoader('NotoSerifSC')
      ..addFont(rootBundle.load('assets/fonts/NotoSerifSC.ttf'));
    await font.load();
    final fallback = await rootBundle.load('assets/fonts/NotoSerifSC.ttf');
    await (FontLoader('Roboto')..addFont(Future.value(fallback))).load();
    await (FontLoader('Ahem')..addFont(Future.value(fallback))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late AppStore store;
  late AppController app;
  late DateTime now;
  setUp(() async {
    now = DateTime(2026, 11, 10, 12);
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => now);
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  final canvas = GlobalKey();
  Widget shell(Widget child, {String language = 'en', bool dark = false}) =>
      MaterialApp(
        locale: Locale(language),
        theme: dayPanelTheme(
          dark ? Brightness.dark : Brightness.light,
          appearance: const Appearance(font: 'serif'),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            RepaintBoundary(key: canvas, child: child!),
        home: child,
      );
  AppLocalizations strings(WidgetTester t) =>
      AppLocalizations.of(t.element(find.byType(Scaffold).last));
  Future<void> setupView(WidgetTester t, bool small) async {
    t.view.physicalSize = small ? const Size(320, 568) : const Size(414, 921);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = small ? 1.6 : 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetViewInsets);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        180,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 45,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .45);
    await t.pumpAndSettle();
    expect(f.hitTestable(), findsOneWidget);
    await t.tap(f);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  void readableCancel(WidgetTester t) {
    final f = find.text(strings(t).cancel).last;
    final paragraph = t.renderObject<RenderParagraph>(f);
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: strings(t).cancel.length),
    );
    expect(
      boxes.map((b) => b.top).toSet().length,
      1,
      reason: 'Short cancel label must not split in the footer',
    );
  }

  Future<void> closeSheet(WidgetTester t) async {
    await tap(t, find.text(strings(t).cancel).last);
  }

  Future<void> shot(WidgetTester t, String name) async {
    await t.pumpAndSettle();
    if (find.byType(EntryEditor).evaluate().isNotEmpty ||
        find.byType(QuantityEditor).evaluate().isNotEmpty) {
      readableCancel(t);
    }
    final boundary =
        canvas.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final f = File('.local/reports/qa02-$name.png');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  Future<void> enter(WidgetTester t, Key key, String value) async {
    final f = find.byKey(key);
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        180,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 45,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .4);
    await t.pumpAndSettle();
    await t.enterText(f, value);
    await t.pumpAndSettle();
  }

  Future<void> openCreate(WidgetTester t) async {
    await tap(t, find.byKey(const Key('add-entry')));
  }

  Future<void> dismissKeyboard(WidgetTester t) async {
    FocusManager.instance.primaryFocus?.unfocus();
    t.view.resetViewInsets();
    await t.pumpAndSettle();
  }

  Future<void> fixture({
    String id = 'h',
    String title = 'Long activity name for reading and careful reflection',
    HabitKind kind = HabitKind.quantity,
    int target = 10000,
    String unit = 'pages',
    int weekdays = 127,
    ScheduleKind schedule = ScheduleKind.weekdays,
  }) async {
    await store.saveHabit(
      Habit(
        id: id,
        title: title,
        kind: kind,
        startDay: app.today.plus(-3),
        target: kind == HabitKind.check ? 1000 : target,
        unit: kind == HabitKind.check ? '' : unit,
        weekdays: weekdays,
        schedule: schedule,
        weeklyGoal: 3,
      ),
      create: true,
      today: app.today,
    );
    await app.load();
  }

  Widget openAction(String label, Future<void> Function(BuildContext) action) =>
      Scaffold(
        body: Builder(
          builder: (c) =>
              TextButton(onPressed: () => action(c), child: Text(label)),
        ),
      );

  const drafts = <String, (String, String, int, String, String, bool)>{
    'water': ('喝水', 'Drink water', 1500000, '毫升', 'ml', false),
    'reading': ('阅读', 'Read', 10000, '页', 'pages', false),
    'walking': ('散步', 'Walk', 6000000, '步', 'steps', false),
    'stretch': ('拉伸', 'Stretch', 10000, '分钟', 'min', false),
    'sleep': ('按时睡觉', 'Sleep on time', 1000, '', '', false),
    'journal': ('写日记', 'Keep a journal', 1000, '', '', false),
    'breakfast': ('吃早餐', 'Eat breakfast', 1000, '', '', false),
    'tidy': ('整理房间', 'Tidy up', 1000, '', '', false),
    'running': ('跑步', 'Run', 3000, '公里', 'km', true),
    'cycling': ('骑行', 'Cycle', 5000, '公里', 'km', true),
    'language': ('学外语', 'Learn a language', 10000, '词', 'words', false),
    'plant': ('照顾植物', 'Care for plants', 1000, '', '', true),
    'music': ('练习乐器', 'Practice music', 15000, '分钟', 'min', false),
    'art': ('画画', 'Draw', 1000, '', '', false),
    'strength': ('力量练习', 'Strength training', 1000, '', '', true),
    'unplug': ('放下手机', 'Put the phone away', 1000, '', '', false),
  };
  for (final lang in ['zh', 'en']) {
    for (final small in [false, true]) {
      testWidgets(
        'QA02 B01/B02/T01-T16 $lang small=$small all template drafts then cancel',
        (t) async {
          await setupView(t, small);
          await t.pumpWidget(
            shell(
              HomePage(app: app),
              language: lang,
              dark: lang == 'en',
            ),
          );
          await t.pumpAndSettle();
          for (final entry in drafts.entries) {
            await openCreate(t);
            await enter(t, const Key('template-search'), entry.key);
            if (find.byKey(Key('template-${entry.key}')).evaluate().isEmpty) {
              await enter(t, const Key('template-search'), entry.value.$1);
            }
            await tap(t, find.byKey(Key('template-${entry.key}')));
            final d = entry.value;
            final e = t.widget<EntryEditor>(find.byType(EntryEditor));
            expect(
              t
                  .widget<TextFormField>(find.byKey(const Key('entry-title')))
                  .controller!
                  .text,
              lang == 'zh' ? d.$1 : d.$2,
            );
            expect(e.template!.chooseSchedule, d.$6);
            expect(
              e.template!.kind,
              d.$4.isEmpty ? HabitKind.check : HabitKind.quantity,
            );
            if (d.$4.isNotEmpty) {
              await Scrollable.ensureVisible(
                t.element(find.byKey(const Key('habit-target'))),
              );
              await t.pumpAndSettle();
              expect(
                t
                    .widget<TextFormField>(
                      find.byKey(const Key('habit-target')),
                    )
                    .controller!
                    .text,
                quantityText(d.$3),
              );
              expect(
                t
                    .widget<TextFormField>(find.byKey(const Key('habit-unit')))
                    .controller!
                    .text,
                lang == 'zh' ? d.$4 : d.$5,
              );
            }
            if (d.$6) {
              await tap(t, find.byKey(const Key('save-entry')));
              expect(app.habits, isEmpty);
              expect(find.text(strings(t).chooseScheduleHelp), findsWidgets);
            }
            if (entry.key == 'reading' || entry.key == 'plant') {
              await shot(
                t,
                'template-${entry.key}-$lang-${small ? 'small' : 'normal'}',
              );
            }
            await closeSheet(t);
            expect(app.habits, isEmpty);
            expect(app.entries, isEmpty);
            expect(t.takeException(), isNull);
          }
          await openCreate(t);
          await enter(
            t,
            const Key('template-search'),
            lang == 'zh'
                ? '看远处，舒缓眼睛，记录一小段轻松的日常'
                : 'Look out the window for a calm moment',
          );
          t.view.viewInsets = const FakeViewPadding(bottom: 230);
          await t.pumpAndSettle();
          expect(
            find.byKey(const Key('custom-habit')).hitTestable(),
            findsOneWidget,
          );
          await shot(
            t,
            'catalog-long-search-$lang-${small ? 'small' : 'normal'}',
          );
          await dismissKeyboard(t);
          await tap(t, find.byKey(const Key('custom-habit')));
          expect(
            t
                .widget<TextFormField>(find.byKey(const Key('entry-title')))
                .controller!
                .text,
            contains(lang == 'zh' ? '看远处' : 'Look out'),
          );
          await closeSheet(t);
          await t.pumpWidget(const SizedBox());
        },
      );

      testWidgets(
        'QA02 C03-C10 $lang small=$small numeric drafts keyboard and invalid values',
        (t) async {
          await setupView(t, small);
          await fixture(
            title: lang == 'zh'
                ? '阅读一本喜爱的书，记录页数和今天的真实进度'
                : 'Read a favourite book and record the actual pages',
          );
          await store.setRecord('h', app.today, 5000, today: app.today);
          await app.load();
          await t.pumpWidget(
            shell(
              openAction(
                'Open',
                (c) => openQuantity(c, app, app.habits.single, app.today),
              ),
              language: lang,
              dark: lang == 'en',
            ),
          );
          await t.pumpAndSettle();
          await tap(t, find.text('Open'));
          await tap(t, find.byKey(const Key('quantity-mode-add')));
          await enter(t, const Key('quantity-input'), '2');
          t.view.viewInsets = const FakeViewPadding(bottom: 230);
          await t.pumpAndSettle();
          expect(
            find.byKey(const Key('quantity-save')).hitTestable(),
            findsOneWidget,
          );
          await shot(
            t,
            'quantity-keyboard-$lang-${small ? 'small' : 'normal'}',
          );
          await dismissKeyboard(t);
          await closeSheet(t);
          expect(app.value(app.habits.single, app.today), 5000);
          await tap(t, find.text('Open'));
          await tap(t, find.byKey(const Key('quantity-mode-add')));
          await enter(t, const Key('quantity-input'), '2');
          await tap(t, find.byKey(const Key('quantity-save')));
          expect(app.value(app.habits.single, app.today), 7000);
          await tap(t, find.text('Open'));
          await enter(t, const Key('quantity-input'), '3');
          await tap(t, find.byKey(const Key('quantity-save')));
          expect(app.value(app.habits.single, app.today), 3000);
          for (final bad in ['-1', '1.2345', 'abc']) {
            await tap(t, find.text('Open'));
            await enter(t, const Key('quantity-input'), bad);
            await tap(t, find.byKey(const Key('quantity-save')));
            expect(app.value(app.habits.single, app.today), 3000);
            expect(find.byType(QuantityEditor), findsOneWidget);
            await closeSheet(t);
          }
          await tap(t, find.text('Open'));
          await enter(t, const Key('quantity-input'), '0');
          await tap(t, find.byKey(const Key('quantity-save')));
          expect(app.value(app.habits.single, app.today), 0);
          await tap(t, find.text('Open'));
          await tap(t, find.byKey(const Key('quantity-clear')));
          expect(app.value(app.habits.single, app.today), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets(
    'QA02 C07/C08/B04/D05 integer counts and schedules cannot silently save invalid drafts',
    (t) async {
      await setupView(t, true);
      await t.pumpWidget(shell(HomePage(app: app)));
      await t.pumpAndSettle();
      await openCreate(t);
      await tap(t, find.byKey(const Key('custom-habit')));
      await enter(t, const Key('entry-title'), 'Practice repetitions');
      await tap(t, find.byKey(const Key('habit-kind-count')));
      for (final bad in ['0', '1.5']) {
        await enter(t, const Key('habit-target'), bad);
        await tap(t, find.byKey(const Key('save-entry')));
        expect(app.habits, isEmpty);
      }
      await enter(t, const Key('habit-target'), '3');
      await tap(t, find.byKey(const Key('habit-schedule-weekly')));
      for (final bad in ['0', '8']) {
        await enter(t, const Key('schedule-number'), bad);
        await tap(t, find.byKey(const Key('save-entry')));
        expect(app.habits, isEmpty);
      }
      await enter(t, const Key('schedule-number'), '3');
      await tap(t, find.byKey(const Key('save-entry')));
      expect(app.habits.single.kind, HabitKind.count);
      expect(app.habits.single.weeklyGoal, 3);
      expect(app.planned, isEmpty);
      await tap(
        t,
        find.byKey(Key('habit-detail-action-${app.habits.single.id}')),
      );
      await enter(t, const Key('quantity-input'), '1.5');
      await tap(t, find.byKey(const Key('quantity-save')));
      expect(app.entries, isEmpty);
      await enter(t, const Key('quantity-input'), '1');
      await tap(t, find.byKey(const Key('quantity-save')));
      expect(app.entries.single.value, 1000);
      expect(app.weekCount(app.habits.single, app.today), 0);
      await tap(
        t,
        find.byKey(Key('habit-detail-action-${app.habits.single.id}')),
      );
      await tap(t, find.byKey(const Key('quantity-mode-add')));
      await enter(t, const Key('quantity-input'), '2');
      await tap(t, find.byKey(const Key('quantity-save')));
      expect(app.entries.single.value, 3000);
      expect(app.weekCount(app.habits.single, app.today), 1);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA02 D07/D08 editing quantity plan preserves today and historical units',
    (t) async {
      await fixture();
      final day = app.today;
      final h = app.habits.single;
      await store.setRecord(h.id, day, 5000, today: day);
      await app.load();
      await t.pumpWidget(
        shell(
          openAction(
            'Edit',
            (c) => openEditor(c, app, 'habit', habit: app.habits.single),
          ),
        ),
      );
      await t.pumpAndSettle();
      await tap(t, find.text('Edit'));
      await enter(t, const Key('habit-target'), '20');
      await enter(t, const Key('habit-unit'), 'minutes');
      await tap(t, find.byKey(const Key('habit-schedule-interval')));
      await enter(t, const Key('schedule-number'), '2');
      await tap(t, find.byKey(const Key('save-entry')));
      expect(app.planAt(app.habits.single, day).unit, 'pages');
      expect(app.planAt(app.habits.single, day).target, 10000);
      expect(app.planAt(app.habits.single, day.plus(1)).unit, 'minutes');
      now = now.add(const Duration(days: 1));
      await app.load();
      expect(app.planAt(app.habits.single, app.today).target, 20000);
      expect(app.value(app.habits.single, day), 5000);
      expect(
        () => store.setRecord(h.id, app.today.plus(1), 1000, today: app.today),
        throwsArgumentError,
      );
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA02 E01/E05 groups create rename duplicate reject and cancelled delete preserve records',
    (t) async {
      await fixture(kind: HabitKind.check);
      await t.pumpWidget(shell(GroupsPage(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.byTooltip(strings(t).newGroup));
      await enter(t, const Key('group-name'), 'Learning');
      await tap(t, find.text(strings(t).save));
      expect(app.groups.single.name, 'Learning');
      await t.pump(const Duration(milliseconds: 400));
      await tap(t, find.byTooltip(strings(t).newGroup));
      await enter(t, const Key('group-name'), 'Learning');
      await tap(t, find.text(strings(t).save));
      expect(app.groups.length, 1);
      await tap(t, find.byTooltip(strings(t).cancel));
      await t.pump(const Duration(milliseconds: 400));
      final g = app.groups.single;
      final original = app.habits.single;
      await store.saveHabit(
        Habit.fromMap({...original.toMap(), 'group_id': g.id}),
        today: app.today,
      );
      await app.load();
      await tap(t, find.text('Learning'));
      await enter(t, const Key('group-name'), 'Learning renamed');
      await tap(t, find.text(strings(t).save));
      await t.pump(const Duration(milliseconds: 400));
      expect(app.groups.single.name, 'Learning renamed');
      await tap(t, find.byTooltip(strings(t).delete));
      await closeSheet(t);
      expect(app.groups.length, 1);
      await tap(t, find.byTooltip(strings(t).delete));
      await tap(t, find.text(strings(t).delete).last);
      expect(app.groups, isEmpty);
      expect(app.habits.single.id, 'h');
      expect(app.habits.single.groupId, isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'QA02 F01/F03 pause and skip preserve or remove only intended rest while records remain real',
    (t) async {
      await fixture(kind: HabitKind.check);
      await t.pumpWidget(shell(HabitDetails(app: app, id: 'h')));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('skip-record-day')));
      await closeSheet(t);
      expect(await store.breaks(), isEmpty);
      await tap(t, find.byKey(const Key('skip-record-day')));
      await tap(t, find.text(strings(t).save));
      expect(app.restOn(app.habits.single, app.today), isNotNull);
      expect(app.entries, isEmpty);
      await tap(t, find.byKey(const Key('skip-record-day')));
      await tap(t, find.text(strings(t).save));
      expect(await store.breaks(), isEmpty);
      await tap(t, find.byKey(const Key('habit-detail-action-h')));
      expect(app.entries.single.value, 1000);
      await tap(t, find.byKey(const Key('habit-settings')));
      await tap(t, find.byKey(const Key('manage-rest-days')));
      await tap(t, find.byKey(const Key('pause-habit')));
      await tap(t, find.text(strings(t).save));
      expect(app.entries.single.value, 1000);
      expect(app.restOn(app.habits.single, app.today), isNotNull);
      final rest = app.rests.single;
      await tap(t, find.byKey(Key('end-rest-${rest.id}')));
      expect(app.restOn(app.habits.single, app.today), isNull);
      expect(app.entries.single.value, 1000);
      await t.pumpWidget(const SizedBox());
    },
  );

  for (final lang in ['zh', 'en']) {
    testWidgets(
      'QA02 G01/G03/G05/G06 $lang short-screen long tasks keyboard and actual today',
      (t) async {
        await setupView(t, true);
        await t.pumpWidget(
          shell(
            HomePage(app: app),
            language: lang,
            dark: lang == 'en',
          ),
        );
        await t.pumpAndSettle();
        await tap(t, find.byKey(const Key('tab-1')));
        final s = strings(t);
        for (final resident in [false, true]) {
          await tap(t, find.byKey(const Key('add-entry')));
          await enter(
            t,
            const Key('entry-title'),
            resident
                ? 'Keep around the household care checklist with a long title'
                : 'Return a library book to a friend with a long title',
          );
          if (resident) {
            await tap(t, find.text(s.residentTask));
          }
          t.view.viewInsets = const FakeViewPadding(bottom: 230);
          await t.pumpAndSettle();
          expect(
            find.byKey(const Key('save-entry')).hitTestable(),
            findsOneWidget,
          );
          await shot(
            t,
            'task-${resident ? 'resident' : 'once'}-keyboard-$lang',
          );
          await dismissKeyboard(t);
          await tap(t, find.byKey(const Key('save-entry')));
          final task = app.tasks.firstWhere((v) => v.resident == resident);
          await tap(t, find.byKey(Key('task-action-${task.id}')));
          expect(
            app.taskDoneOn(
              app.tasks.firstWhere((v) => v.id == task.id),
              app.today,
            ),
            isTrue,
          );
          await tap(t, find.byKey(Key('task-action-${task.id}')));
          expect(
            app.taskDoneOn(
              app.tasks.firstWhere((v) => v.id == task.id),
              app.today,
            ),
            isFalse,
          );
        }
        expect(app.taskEntries, isEmpty);
        expect(app.tasks.length, 2);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
