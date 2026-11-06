import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/appearance.dart';
import 'package:daypanel/presentation/backup_page.dart';
import 'package:daypanel/presentation/theme.dart';
import 'package:daypanel/domain/appearance.dart';

void main() {
  sqfliteFfiInit();
  for (final locale in ['en', 'zh']) {
    for (final dark in [false, true]) {
      testWidgets(
        'UI02 $locale dark=$dark accessible backup and appearance actions',
        (t) async {
          final store = await AppStore.open(
            factory: databaseFactoryFfiNoIsolate,
            path: inMemoryDatabasePath,
          );
          final app = AppController(store);
          await app.load();
          addTearDown(() async {
            app.dispose();
            await store.close();
          });
          t.view.physicalSize = const Size(360, 800);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final semantics = t.ensureSemantics();
          try {
            Widget shell(Widget home) => MaterialApp(
              locale: Locale(locale),
              theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: home,
            );
            await t.pumpWidget(shell(BackupPage(app: app)));
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
            await expectLater(t, meetsGuideline(androidTapTargetGuideline));
            await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
            await t.pumpWidget(const SizedBox());
            await store.saveAppearance(
              Appearance(mode: dark ? 'dark' : 'light'),
            );
            await app.load();
            await t.pumpWidget(shell(AppearancePage(app: app)));
            await t.pumpAndSettle();
            await expectLater(t, meetsGuideline(androidTapTargetGuideline));
            await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
            await t.pumpWidget(const SizedBox());
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
