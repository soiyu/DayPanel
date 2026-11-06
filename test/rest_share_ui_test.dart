import 'package:flutter/material.dart';
import 'dart:ui' show SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/card_image.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/habit_break.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/rest_days.dart';
import 'package:daypanel/presentation/card_share.dart';
import 'package:daypanel/presentation/theme.dart';

class MemoryCardImages implements CardImageFiles {
  Uint8List? png;
  int shared = 0;
  bool saved = true;
  @override
  Future<bool> save(Uint8List bytes, String name) async {
    png = bytes;
    return saved;
  }

  @override
  Future<void> share(Uint8List bytes, String name) async {
    png = bytes;
    shared++;
  }
}

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late Habit h;
  late MemoryCardImages files;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => DateTime(2026, 11, 7));
    files = MemoryCardImages();
    h = Habit(
      id: 'h',
      title: 'Private habit',
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
  Widget shell(Widget child, {String lang = 'en', bool dark = false}) =>
      MaterialApp(
        locale: Locale(lang),
        theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );
  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        180,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(
      t.element(f),
      alignment: .4,
      duration: Duration.zero,
    );
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> earned() async {
    await store.setRecord('h', app.today, 1000, today: app.today);
    await store.reflectOnCard(app.today, 'Private reflection');
    await app.load();
  }

  testWidgets(
    'pause confirmation cancel stays active; save pauses; explicit resume restores',
    (t) async {
      await t.pumpWidget(shell(RestDaysPage(app: app, id: 'h')));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('pause-habit')));
      await tap(t, find.text('Cancel'));
      expect(await store.breaks(), isEmpty);
      await tap(t, find.byKey(const Key('pause-habit')));
      await tap(t, find.text('Save'));
      expect(app.restOn(h, app.today)!.kind, BreakKind.pause);
      expect(app.dailyPlanned, isEmpty);
      await tap(t, find.byKey(Key('end-rest-${app.rests.single.id}')));
      expect(app.rests, isEmpty);
      expect(app.dailyPlanned.length, 1);
    },
  );
  testWidgets(
    'skip confirmation preserves cancel and clears only selected rest',
    (t) async {
      await t.pumpWidget(
        shell(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => skipDay(context, app, h, app.today),
                child: const Text('Skip'),
              ),
            ),
          ),
        ),
      );
      await tap(t, find.text('Skip'));
      await tap(t, find.text('Cancel'));
      expect(await store.breaks(), isEmpty);
      await tap(t, find.text('Skip'));
      await tap(t, find.text('Save'));
      expect((await store.breaks()).single.kind, BreakKind.skip);
      expect(await store.entries(), isEmpty);
    },
  );
  testWidgets('old pause confirmation after recovery cannot write', (t) async {
    await t.pumpWidget(shell(RestDaysPage(app: app, id: 'h')));
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('pause-habit')));
    final snap = await store.exportSnapshot();
    await app.run(() => store.restoreSnapshot(snap));
    await tap(t, find.text('Save'));
    expect(await store.breaks(), isEmpty);
  });
  testWidgets('rest page opened before recovery cannot start another action', (
    t,
  ) async {
    await t.pumpWidget(shell(RestDaysPage(app: app, id: 'h')));
    await t.pumpAndSettle();
    await app.run(
      () async => store.restoreSnapshot(await store.exportSnapshot()),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('pause-habit')), findsNothing);
    expect(find.textContaining('This habit changed'), findsOneWidget);
    expect(await store.breaks(), isEmpty);
  });
  testWidgets('resume has its own named accessible action', (t) async {
    final semantics = t.ensureSemantics();
    await store.addBreak(
      HabitBreak(
        id: 'rest',
        habitId: h.id,
        start: app.today,
        kind: BreakKind.pause,
      ),
      today: app.today,
    );
    await app.load();
    await t.pumpWidget(shell(RestDaysPage(app: app, id: 'h')));
    await t.pumpAndSettle();
    final action = find.byKey(const Key('end-rest-rest'));
    expect(t.getSemantics(action).label, 'Resume today');
    expect(
      t.getSemantics(action).getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });
  testWidgets(
    'share defaults hide personal details; toggles and excerpt do not edit original',
    (t) async {
      await earned();
      await t.pumpWidget(
        shell(
          CardSharePage(
            app: app,
            day: app.today,
            title: 'A bright day',
            files: files,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('Private habit'), findsNothing);
      expect(find.text('Private reflection'), findsNothing);
      await tap(t, find.byKey(const Key('share-names')));
      expect(find.textContaining('Private habit'), findsOneWidget);
      await tap(t, find.byKey(const Key('share-reflection')));
      await t.enterText(
        find.byKey(const Key('share-excerpt')),
        'Share this only',
      );
      await t.pumpAndSettle();
      expect((await store.cards()).single.reflection, 'Private reflection');
      expect(files.png, isNull);
    },
  );
  testWidgets('stale share page cannot export after restore', (t) async {
    await earned();
    await t.pumpWidget(
      shell(
        CardSharePage(
          app: app,
          day: app.today,
          title: 'A bright day',
          files: files,
        ),
      ),
    );
    await t.pumpAndSettle();
    final snap = await store.exportSnapshot();
    await app.run(() => store.restoreSnapshot(snap));
    await tap(t, find.byKey(const Key('save-card-image')));
    expect(files.png, isNull);
    expect(find.textContaining('Card data changed'), findsOneWidget);
  });
  for (final lang in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$lang dark=$dark rest and share 320dp 160% keyboard actions fit',
        (t) async {
          t.view.physicalSize = const Size(320, 800);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(t.view.resetViewInsets);
          await t.pumpWidget(
            shell(
              RestDaysPage(app: app, id: 'h'),
              lang: lang,
              dark: dark,
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          await earned();
          await t.pumpWidget(
            shell(
              CardSharePage(
                app: app,
                day: app.today,
                title: '每天的一点进步 · A little progress',
                files: files,
              ),
              lang: lang,
              dark: dark,
            ),
          );
          await t.pumpAndSettle();
          await tap(t, find.byKey(const Key('share-reflection')));
          t.view.viewInsets = const FakeViewPadding(bottom: 280);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(
            find.byKey(const Key('save-card-image')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('share-card-image')).hitTestable(),
            findsOneWidget,
          );
        },
      );
    }
  }
}
