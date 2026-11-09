import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/achievements.dart';
import 'package:daypanel/presentation/card_art.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  sqfliteFfiInit();
  for (final lang in ['zh', 'en']) {
    testWidgets(
      '$lang guide explains all six artworks without earning or changing data',
      (t) async {
        final store = await AppStore.open(
          factory: databaseFactoryFfiNoIsolate,
          path: inMemoryDatabasePath,
        );
        final app = AppController(store, clock: () => DateTime(2026, 11, 9));
        await app.load();
        final before = (await store.exportSnapshot()).tables;
        t.view.physicalSize = const Size(320, 720);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            theme: dayPanelTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CardCollection(app: app),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('card-guide')));
        await t.pumpAndSettle();
        expect(find.byType(CardGuidePage), findsOneWidget);
        final s = AppLocalizations.of(t.element(find.byType(CardGuidePage)));
        expect(find.text(s.cardPurpose), findsOneWidget);
        for (var i = 0; i < 6; i++) {
          final f = find.byKey(Key('card-art-preview-$i'));
          if (f.evaluate().isEmpty) {
            await t.scrollUntilVisible(
              f,
              250,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await Scrollable.ensureVisible(t.element(f));
          await t.pumpAndSettle();
          expect(
            find.descendant(of: f, matching: find.text(cardTitle(s, i))),
            findsOneWidget,
          );
          expect(
            t
                .widget<CardArt>(
                  find.descendant(of: f, matching: find.byType(CardArt)),
                )
                .artwork,
            i,
          );
          expect(t.takeException(), isNull);
        }
        await t.scrollUntilVisible(
          find.text(s.cardGuideShare),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        expect(find.text(s.cardGuideShare), findsOneWidget);
        expect((await store.exportSnapshot()).tables, before);
        expect(app.cards, isEmpty);
        await t.tap(
          find.byTooltip(
            MaterialLocalizations.of(
              t.element(find.byType(CardGuidePage)),
            ).backButtonTooltip,
          ),
        );
        await t.pumpAndSettle();
        expect(find.byType(CardCollection), findsOneWidget);
        await t.pumpWidget(const SizedBox());
        app.dispose();
        await store.close();
      },
    );
  }
}
