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
import 'package:daypanel/presentation/components.dart';
import 'package:daypanel/presentation/habits.dart';
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
  for (final statistics in [false, true]) {
    testWidgets(
      statistics
          ? 'long selected habit keeps its statistics table visible and full name available'
          : 'long daily habit keeps recording above navigation and full name in details',
      (t) async {
        t.view.physicalSize = const Size(320, 568);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = t.ensureSemantics();
        try {
          for (final language in ['en', 'zh']) {
            final store = await AppStore.open(
              factory: databaseFactoryFfiNoIsolate,
              path: inMemoryDatabasePath,
            );
            final app = AppController(
              store,
              clock: () => DateTime(2026, 11, 10),
            );
            final title = language == 'en'
                ? 'Read a chapter and keep a meaningful sentence'
                : '阅读今天感兴趣的书并记下一段有意义的话';
            final habit = Habit(
              id: 'long-read',
              title: title,
              kind: HabitKind.quantity,
              target: 10000,
              unit: language == 'en' ? 'pages' : '页',
              startDay: app.today.plus(-7),
            );
            await store.saveHabit(habit, create: true, today: app.today);
            await store.preference('font', 'serif');
            await app.load();
            final boundary = GlobalKey();
            try {
              await t.pumpWidget(
                RepaintBoundary(
                  key: boundary,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    locale: Locale(language),
                    theme: dayPanelTheme(
                      Brightness.dark,
                      appearance: const Appearance(font: 'serif'),
                    ),
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: statistics
                        ? StatisticsPage(app: app, habitId: habit.id)
                        : HomePage(app: app),
                  ),
                ),
              );
              await t.pumpAndSettle();
              final s = AppLocalizations.of(
                t.element(find.byType(Scaffold).first),
              );
              if (statistics) {
                final cell = find.byKey(
                  Key('matrix-${habit.id}-${app.today.key}'),
                );
                expect(
                  cell.hitTestable(),
                  findsOneWidget,
                  reason:
                      'An actual check-in cell must be visible before scrolling',
                );
                expect(t.getRect(cell).top, lessThan(568 - 48));
                final filter = find.byKey(const Key('statistics-habit-filter'));
                final text = find.descendant(
                  of: filter,
                  matching: find.text(title),
                );
                final paragraph = t.renderObject<RenderParagraph>(text);
                expect(paragraph.maxLines, 2);
                expect(paragraph.overflow, TextOverflow.ellipsis);
                expect(t.getSemantics(filter).label, contains(title));
                await capture(
                  t,
                  boundary,
                  'qa02-long-title-$language-statistics',
                );
                await t.tap(filter);
                await t.pumpAndSettle();
                final choice = find.descendant(
                  of: find.byType(SheetFrame),
                  matching: find.text(title),
                );
                expect(choice, findsOneWidget);
                expect(t.widget<Text>(choice).maxLines, isNull);
                await t.ensureVisible(choice);
                await t.pumpAndSettle();
                await t.tap(choice);
                await t.pumpAndSettle();
                expect(cell.hitTestable(), findsOneWidget);
                expect(app.entries, isEmpty);
              } else {
                final action = find.byKey(Key('habit-action-${habit.id}'));
                expect(
                  action.hitTestable(),
                  findsOneWidget,
                  reason:
                      'Long names must not push the primary record action below navigation',
                );
                final navigationTop = t
                    .getTopLeft(find.byType(GlassNavigation))
                    .dy;
                expect(t.getRect(action).bottom, lessThan(navigationTop));
                final titleText = find.descendant(
                  of: find.byType(HabitTile),
                  matching: find.text(title),
                );
                final paragraph = t.renderObject<RenderParagraph>(titleText);
                expect(paragraph.maxLines, 2);
                expect(paragraph.overflow, TextOverflow.ellipsis);
                expect(t.getSemantics(titleText).label, contains(title));
                expect(
                  t.getRect(action).top,
                  greaterThan(t.getRect(titleText).bottom),
                );
                await capture(t, boundary, 'qa02-long-title-$language-daily');
                await t.tap(action);
                await t.pumpAndSettle();
                expect(find.byKey(const Key('quantity-input')), findsOneWidget);
                await t.tap(find.text(s.cancel));
                await t.pumpAndSettle();
                expect(app.entries, isEmpty);
                await t.tap(titleText);
                await t.pumpAndSettle();
                expect(find.byType(HabitDetails), findsOneWidget);
                final detailTitle = find.descendant(
                  of: find.byType(HabitTile),
                  matching: find.text(title),
                );
                expect(detailTitle, findsOneWidget);
                expect(t.widget<Text>(detailTitle).maxLines, isNull);
              }
              expect(t.takeException(), isNull);
            } finally {
              await t.pumpWidget(const SizedBox());
              app.dispose();
              await store.close();
            }
          }
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}

Future<void> capture(WidgetTester t, GlobalKey key, String name) async {
  await t.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
            .toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('.local/reports/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
