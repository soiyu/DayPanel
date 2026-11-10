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
import 'package:daypanel/presentation/home.dart';
import 'package:daypanel/presentation/statistics.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  setUpAll(() async {
    await (FontLoader(
      'NotoSerifSC',
    )..addFont(rootBundle.load('assets/fonts/NotoSerifSC.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final language in ['en', 'zh']) {
    for (final statistics in [true, false]) {
      testWidgets(
        '$language ${statistics ? 'statistics' : 'home'} navigation preserves words taps and selection after resize',
        (t) async {
          final store = await AppStore.open(
            factory: databaseFactoryFfiNoIsolate,
            path: inMemoryDatabasePath,
          );
          final app = AppController(store, clock: () => DateTime(2026, 11, 10));
          await store.saveHabit(
            Habit(
              id: 'read',
              title: language == 'en' ? 'Read' : '阅读',
              kind: HabitKind.check,
              startDay: app.today,
            ),
            create: true,
            today: app.today,
          );
          await store.preference('font', 'serif');
          await app.load();
          addTearDown(() async {
            app.dispose();
            await store.close();
          });
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final semantics = t.ensureSemantics();

          final boundary = GlobalKey();
          final page = statistics
              ? StatisticsPage(app: app)
              : HomePage(app: app);
          try {
            for (final small in [false, true, false]) {
              t.view.physicalSize = small
                  ? const Size(320, 568)
                  : const Size(414, 921);
              t.platformDispatcher.textScaleFactorTestValue = small ? 1.6 : 1;
              await t.pumpWidget(
                RepaintBoundary(
                  key: boundary,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    locale: Locale(language),
                    theme: dayPanelTheme(
                      small ? Brightness.dark : Brightness.light,
                      appearance: const Appearance(font: 'serif'),
                    ),
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: page,
                  ),
                ),
              );
              await t.pumpAndSettle();
              final s = AppLocalizations.of(
                t.element(find.byType(page.runtimeType)),
              );
              final labels = statistics
                  ? [s.uiTabTable, s.uiTabHabits, s.uiTabYear, s.uiTabTimeline]
                  : [s.today, s.tasks, s.notes, s.mine];
              final semanticLabels = statistics
                  ? [
                      s.checkinTable,
                      s.habitStatistics,
                      s.yearCalendar,
                      s.timelineTitle,
                    ]
                  : labels;
              Finder tab(int i) =>
                  find.byKey(Key('${statistics ? 'statistics-' : ''}tab-$i'));
              final tabTops = [
                for (var i = 0; i < 4; i++) t.getTopLeft(tab(i)).dy,
              ];
              if (!small || !statistics) {
                expect(
                  tabTops.toSet().length,
                  1,
                  reason: 'Normal navigation keeps all four items in a row',
                );
              }
              for (var selected = 0; selected < 4; selected++) {
                final action = tab(selected);
                expect(action.hitTestable(), findsOneWidget);
                final size = t.getSize(action);
                expect(size.width, greaterThanOrEqualTo(48));
                expect(size.height, greaterThanOrEqualTo(48));
                await t.tap(action);
                await t.pumpAndSettle();
                expect(t.takeException(), isNull);
                for (var i = 0; i < 4; i++) {
                  final label = find.descendant(
                    of: tab(i),
                    matching: find.text(labels[i]),
                  );
                  final paragraph = t.renderObject<RenderParagraph>(label);
                  final boxes = paragraph.getBoxesForSelection(
                    TextSelection(
                      baseOffset: 0,
                      extentOffset: labels[i].length,
                    ),
                  );
                  expect(
                    boxes.map((box) => box.top).toSet().length,
                    1,
                    reason:
                        '${labels[i]} must remain a whole label at ${small ? '320dp/160%' : '414dp/100%'}',
                  );
                  final node = t.getSemantics(tab(i)).getSemanticsData();
                  expect(node.flagsCollection.isButton, isTrue);
                  expect(
                    node.flagsCollection.isSelected,
                    i == selected ? ui.Tristate.isTrue : ui.Tristate.isFalse,
                  );
                  expect(node.hasAction(ui.SemanticsAction.tap), isTrue);
                  expect(node.label, contains(semanticLabels[i]));
                }
                if (!statistics) {
                  expect(
                    find.descendant(
                      of: find.byType(AppBar),
                      matching: find.text(labels[selected]),
                    ),
                    findsOneWidget,
                  );
                }
              }
              if (small) {
                await t.runAsync(() async {
                  final image =
                      await (boundary.currentContext!.findRenderObject()
                              as RenderRepaintBoundary)
                          .toImage(pixelRatio: 1.5);
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  image.dispose();
                  final file = File(
                    '.local/reports/qa02-navigation-$language-${statistics ? 'statistics' : 'home'}.png',
                  );
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(bytes!.buffer.asUint8List());
                });
              }
            }
            await t.pumpWidget(const SizedBox());
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
