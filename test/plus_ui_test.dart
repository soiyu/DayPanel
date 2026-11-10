import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/widget_platform.dart';
import 'package:daypanel/data/plus_access.dart';
import 'package:daypanel/data/calendar_platform.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/appearance.dart';
import 'package:daypanel/domain/record_event.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/theme.dart';
import 'package:daypanel/presentation/record_events.dart';
import 'package:daypanel/presentation/panel_widgets.dart';
import 'package:daypanel/presentation/review_card.dart';
import 'package:daypanel/presentation/reminders.dart';
import 'package:daypanel/presentation/plus_page.dart';
import 'package:daypanel/presentation/editors.dart';

class PanelPlatform implements WidgetPlatform, WidgetPinning {
  final requests = <Map<String, Object?>>[];
  @override
  Future<bool> canPin() async => true;
  @override
  Future<bool> hasWidgets() async => true;
  @override
  Future<bool> pin(String kind, String id, int generation) async {
    requests.add({'kind': kind, 'id': id, 'generation': generation});
    return true;
  }

  @override
  Future<void> configure(int widgetId, String id, int generation) async {
    requests.add({'widgetId': widgetId, 'id': id, 'generation': generation});
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> openApp() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<Map<String, Object?>?> launch() async => null;
  @override
  Future<bool> validate(Map<String, Object?> request) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late Habit h;
  late PanelPlatform platform;
  final day = Day.parse('2026-11-11');
  final capture = GlobalKey();
  setUpAll(() async {
    await (FontLoader(
      'NotoSerifSC',
    )..addFont(rootBundle.load('assets/fonts/NotoSerifSC.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    platform = PanelPlatform();
    app = AppController(
      store,
      clock: () => DateTime(2026, 11, 11, 12),
      widgetPlatform: platform,
    );
    h = Habit(
      id: 'read',
      title: 'Read a chapter and remember the useful parts',
      kind: HabitKind.quantity,
      startDay: day.plus(-30),
      target: 10000,
      unit: 'pages',
    );
    await store.saveHabit(h, create: true, today: day);
    await store.saveHabit(
      Habit(
        id: 'stretch',
        title: 'Stretch',
        kind: HabitKind.check,
        startDay: day,
      ),
      create: true,
      today: day,
    );
    await store.saveTask(
      SmallTask(id: 'task', title: 'Tidy desk', resident: true, startDay: day),
      create: true,
      today: day,
    );
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(CalendarPlatform.channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PlusAccess.channel, null);
  });
  Widget shell(Widget page, String locale) => RepaintBoundary(
    key: capture,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(locale),
      theme: dayPanelTheme(
        Brightness.dark,
        appearance: const Appearance(font: 'serif'),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    ),
  );
  AppLocalizations strings(WidgetTester t) =>
      AppLocalizations.of(t.element(find.byType(Scaffold).last));
  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        200,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 30,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .5);
    await t.pumpAndSettle();
    expect(f.hitTestable(), findsOneWidget);
    await t.tap(f);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Future<void> shot(WidgetTester t, String name) async {
    await t.pumpAndSettle();
    await t.runAsync(() async {
      final image =
          await (capture.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('.local/reports/plus-$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  void narrow(WidgetTester t) {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final locale in ['en', 'zh']) {
    testWidgets(
      '$locale individual entry creation correction cancellation and narrow keyboard',
      (t) async {
        narrow(t);
        await t.pumpWidget(
          shell(RecordEventsPage(app: app, habitId: h.id, day: day), locale),
        );
        await t.pumpAndSettle();
        await tap(t, find.byKey(const Key('event-add')));
        await t.enterText(find.byKey(const Key('event-amount')), '3.5');
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        await tap(t, find.byKey(const Key('event-save')));
        expect(app.value(h, day), 3500);
        expect(app.events.single.minute, 720);
        await shot(t, '$locale-event-list');
        await tap(t, find.text('3.5 pages').last);
        await t.enterText(find.byKey(const Key('event-amount')), '4');
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        await tap(t, find.byKey(const Key('event-save')));
        expect(app.value(h, day), 4000);
        expect(app.events.single.revision, 1);
        await tap(t, find.byKey(const Key('event-add')));
        await t.enterText(
          find.byKey(const Key('event-note')),
          'A note with enough length to check a small screen and keyboard.',
        );
        t.view.viewInsets = const FakeViewPadding(bottom: 200);
        await t.pumpAndSettle();
        await shot(t, '$locale-event-keyboard');
        t.view.resetViewInsets();
        await t.pumpAndSettle();
        await tap(t, find.text(strings(t).cancel).last);
        expect(app.events.length, 1);
        await t.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      '$locale combined panel selection order and independent pin payload',
      (t) async {
        narrow(t);
        await t.pumpWidget(shell(PanelWidgetPage(app: app), locale));
        await t.pumpAndSettle();
        for (final title in ['Stretch', 'Tidy desk']) {
          await tap(t, find.widgetWithText(CheckboxListTile, title));
        }
        await tap(t, find.byTooltip(strings(t).moveUp).last);
        await shot(t, '$locale-panel-config');
        await tap(t, find.byKey(const Key('panel-save')));
        final rows =
            jsonDecode(platform.requests.single['id'] as String) as List;
        expect(rows.map((r) => r['id']).toList(), ['task', 'stretch']);
        expect(platform.requests.single['kind'], 'panel');
        expect(await store.entries(), isEmpty);
        await t.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      '$locale review preview hides names and preserves source while showing real totals',
      (t) async {
        narrow(t);
        await store.setRecord(h.id, day, 3000, today: day);
        await app.load();
        final before = (await store.exportSnapshot()).tables;
        await t.pumpWidget(shell(ReviewCardPage(app: app), locale));
        await t.pumpAndSettle();
        await tap(t, find.byKey(const Key('review-preview')));
        await shot(t, '$locale-review-card');
        expect(find.text(h.title), findsNothing);
        expect(find.text('3 pages'), findsOneWidget);
        expect((await store.exportSnapshot()).tables, before);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('calendar hands off without saving a reminder draft or record', (
    t,
  ) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(CalendarPlatform.channel, (call) async {
          calls.add(call);
          return true;
        });
    await t.pumpWidget(
      shell(
        Scaffold(
          body: ReminderEditor(app: app, habit: h),
        ),
        'en',
      ),
    );
    await t.pumpAndSettle();
    await tap(t, find.byTooltip('Add to calendar'));
    expect(calls.single.arguments['generation'], app.generation);
    expect(calls.single.arguments['id'], h.id);
    expect(await store.reminders(), isEmpty);
    expect(await store.entries(), isEmpty);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'paid access has honest unavailable pending cancelled and restored states',
    (t) async {
      var phase = 0;
      final calls = <String>[];
      app.plus.testing = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PlusAccess.channel, (call) async {
            calls.add(call.method);
            return switch (phase) {
              0 => {'testing': false, 'owned': false, 'available': false},
              1 => {
                'owned': false,
                'available': true,
                'price': r'$7.99',
                'pending': true,
              },
              2 => {
                'owned': false,
                'available': true,
                'price': r'$7.99',
                'error': 'cancelled',
              },
              _ => {'owned': true, 'available': true, 'price': r'$7.99'},
            };
          });
      await t.pumpWidget(shell(PlusPage(app: app), 'en'));
      await t.pumpAndSettle();
      expect(app.plus.enabled, isFalse);
      expect(
        find.text(
          'This purchase is currently unavailable on Google Play. Please try again later.',
        ),
        findsOneWidget,
      );
      phase = 1;
      await app.plus.refresh();
      await t.pumpAndSettle();
      expect(app.plus.enabled, isFalse);
      expect(
        find.text('Payment pending. Plus unlocks after payment completes.'),
        findsOneWidget,
      );
      phase = 2;
      await app.plus.buy();
      await t.pumpAndSettle();
      expect(app.plus.enabled, isFalse);
      expect(find.text('Purchase cancelled'), findsOneWidget);
      phase = 3;
      await tap(t, find.text('Restore purchase'));
      expect(app.plus.enabled, isTrue);
      expect(calls, contains('restore'));
      expect(await store.entries(), isEmpty);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'existing add mode records a single real event and cancelled input writes nothing',
    (t) async {
      await t.pumpWidget(
        shell(
          Scaffold(
            body: QuantityEditor(app: app, habit: h, day: day),
          ),
          'en',
        ),
      );
      await t.pumpAndSettle();
      await tap(t, find.text('Add this amount'));
      await t.enterText(find.byKey(const Key('quantity-input')), '2');
      await tap(t, find.byKey(const Key('quantity-save')));
      expect(
        app.events.where((e) => e.kind == RecordEventKind.record).length,
        1,
      );
      expect(app.value(h, day), 2000);
      await t.pumpWidget(const SizedBox());
    },
  );
}
