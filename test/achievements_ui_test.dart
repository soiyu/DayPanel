import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/achievements.dart';
import 'package:daypanel/presentation/card_art.dart';
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
        title: 'A little reading 阅读',
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
  Widget shell(
    Widget child, {
    String language = 'en',
    bool dark = false,
    bool reduced = false,
  }) => MaterialApp(
    locale: Locale(language),
    theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: child!,
    ),
    home: child,
  );
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> earn() async {
    await store.setRecord('h', app.today, 1000, today: app.today);
    await app.load();
  }

  testWidgets(
    'earned card flips favorites edits reflection and cancel preserves prior text',
    (tester) async {
      await earn();
      await tester.pumpWidget(shell(CardDetails(app: app, day: app.today)));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('favorite-card')));
      expect(app.cards.single.favorite, isTrue);
      await tap(tester, find.byKey(const Key('flip-card')));
      expect(find.text('Words on the back'), findsOneWidget);
      await tap(tester, find.byKey(const Key('edit-reflection')));
      await tester.enterText(
        find.byKey(const Key('reflection-text')),
        'A calm moment',
      );
      await tap(tester, find.byKey(const Key('save-reflection')));
      expect(app.cards.single.reflection, 'A calm moment');
      await tap(tester, find.byKey(const Key('edit-reflection')));
      await tester.enterText(
        find.byKey(const Key('reflection-text')),
        'Discard me',
      );
      await tap(tester, find.text('Cancel'));
      expect(app.cards.single.reflection, 'A calm moment');
      await tap(tester, find.byKey(const Key('edit-reflection')));
      await tester.enterText(find.byKey(const Key('reflection-text')), '');
      await tap(tester, find.byKey(const Key('save-reflection')));
      expect(app.cards.single.reflection, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'collection filters actual favorites and back changes neither data nor completion',
    (tester) async {
      await earn();
      await tester.pumpWidget(shell(CardCollection(app: app)));
      await tester.pumpAndSettle();
      expect(find.byType(CardArt), findsOneWidget);
      await tap(tester, find.byKey(const Key('favorite-filter')));
      expect(find.text('No favorites yet'), findsOneWidget);
      await store.favoriteCard(app.today, true);
      await app.load();
      await tester.pumpAndSettle();
      expect(find.byType(CardArt), findsOneWidget);
      await tap(tester, find.byType(CardArt));
      await tap(tester, find.byKey(const Key('edit-reflection')));
      await tester.enterText(
        find.byKey(const Key('reflection-text')),
        'Back discards',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(app.cards.single.reflection, isEmpty);
      expect(app.entries.single.value, 1000);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'old reflection editor is rejected after restore without erasing saved words',
    (tester) async {
      await earn();
      await store.reflectOnCard(app.today, 'Saved');
      await app.load();
      final snapshot = await store.exportSnapshot();
      await tester.pumpWidget(shell(CardDetails(app: app, day: app.today)));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('edit-reflection')));
      await tester.enterText(find.byKey(const Key('reflection-text')), 'Stale');
      await app.run(() => store.restoreSnapshot(snapshot));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('save-reflection')));
      expect(app.cards.single.reflection, 'Saved');
      expect(find.byKey(const Key('save-reflection')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'claim from migrated completed data persists card and rechecks day',
    (tester) async {
      await store.db.insert('entries', {
        'habit_id': 'h',
        'day': app.today.key,
        'value': 1000,
      });
      await app.load();
      await tester.pumpWidget(
        shell(
          Scaffold(
            body: DailyCardPanel(app: app, day: app.today),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('claim-card')));
      expect(app.cards.single.day, app.today);
      expect(find.byType(CardDetails), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'reduced motion disables card flip and switches persist explicit settings',
    (tester) async {
      await earn();
      await tester.pumpWidget(
        shell(CardDetails(app: app, day: app.today), reduced: true),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher).first)
            .duration,
        Duration.zero,
      );
      await tap(tester, find.byKey(const Key('flip-card')));
      expect(find.byKey(const ValueKey('card-back')), findsOneWidget);
      await tester.pumpWidget(shell(FeedbackPage(app: app)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Switch>(find.byKey(const Key('completion_sound'))).value,
        isFalse,
      );
      await tap(tester, find.byKey(const Key('completion_sound')));
      await tap(tester, find.byKey(const Key('completion_haptics')));
      expect((await store.settings())['completion_sound'], 'on');
      expect((await store.settings())['completion_haptics'], 'on');
      await tap(tester, find.byKey(const Key('completion_sound')));
      expect((await store.settings())['completion_sound'], 'off');
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final language in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$language ${dark ? 'dark' : 'light'} all artwork and reflection settings fit narrow large text keyboard',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          for (var i = 5; i >= 0; i--) {
            final day = app.today.plus(-i);
            await store.setRecord('h', day, 1000, today: day);
          }
          await app.load();
          expect(app.cards.map((c) => c.artwork).toSet().length, 6);
          for (final card in app.cards) {
            await tester.pumpWidget(
              shell(
                CardDetails(key: ValueKey(card.day), app: app, day: card.day),
                language: language,
                dark: dark,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tap(tester, find.byKey(const Key('flip-card')));
          await tap(tester, find.byKey(const Key('edit-reflection')));
          await tester.enterText(
            find.byKey(const Key('reflection-text')),
            'Narrow screen note 窄屏心得',
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('save-reflection')).hitTestable(),
            findsOneWidget,
          );
          await tap(tester, find.byKey(const Key('save-reflection')));
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(app.cards.last.reflection, 'Narrow screen note 窄屏心得');
          await tester.pumpWidget(
            shell(
              FeedbackPage(app: app),
              language: language,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          await tap(tester, find.byKey(const Key('completion_sound')));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            shell(
              CardCollection(app: app),
              language: language,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          await tap(tester, find.byKey(const Key('favorite-filter')));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
