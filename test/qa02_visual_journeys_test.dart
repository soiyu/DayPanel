import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/reminder.dart';
import 'package:daypanel/domain/appearance.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/theme.dart';
import 'package:daypanel/presentation/home.dart';
import 'package:daypanel/presentation/journal.dart';
import 'package:daypanel/presentation/statistics.dart';
import 'package:daypanel/presentation/achievements.dart';
import 'package:daypanel/presentation/card_share.dart';
import 'package:daypanel/presentation/appearance.dart';
import 'package:daypanel/presentation/backup_page.dart';
import 'package:daypanel/presentation/reminders.dart';
import 'package:daypanel/presentation/home_widgets.dart';
import 'package:daypanel/presentation/review.dart';
import 'package:daypanel/presentation/tasks.dart';
import 'reminders_test.dart' show FakeReminderPlatform;
import 'home_widgets_test.dart' show FakeWidgets;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  setUpAll(() async {
    // Use the app's bundled licensed font, never the test-only Ahem boxes.
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/NotoSerifSC.ttf'));
    await font.load();
    final serif = FontLoader('NotoSerifSC')
      ..addFont(rootBundle.load('assets/fonts/NotoSerifSC.ttf'));
    await serif.load();
    final fallback = FontLoader('Ahem')
      ..addFont(rootBundle.load('assets/fonts/NotoSerifSC.ttf'));
    await fallback.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final lang in ['zh', 'en']) {
    for (final small in [false, true]) {
      testWidgets('QA02 H I J K L M N screens $lang small=$small long content', (
        t,
      ) async {
        final store = await AppStore.open(
          factory: databaseFactoryFfiNoIsolate,
          path: inMemoryDatabasePath,
        );
        final app = AppController(
          store,
          clock: () => DateTime(2026, 11, 10),
          reminderPlatform: FakeReminderPlatform(),
          widgetPlatform: FakeWidgets(),
        );
        final name = lang == 'zh'
            ? '阅读今天感兴趣的书并记下一段有意义的话'
            : 'Read a chapter and keep a meaningful sentence';
        final h = Habit(
          id: 'read',
          title: name,
          kind: HabitKind.quantity,
          startDay: app.today.plus(-40),
          target: 10000,
          unit: lang == 'zh' ? '页' : 'pages',
          icon: 2,
        );
        await store.saveHabit(h, create: true, today: app.today.plus(-40));
        for (var i = 0; i < 14; i++) {
          await store.setRecord(
            h.id,
            app.today.plus(-i),
            i == 0 ? 10000 : 5000 + i * 1000,
            today: app.today,
          );
        }
        await store.saveTask(
          SmallTask(
            id: 'r',
            title: lang == 'zh'
                ? '按需要整理房间与书桌'
                : 'Tidy the room and desk when needed',
            resident: true,
            startDay: app.today,
          ),
          create: true,
          today: app.today,
        );
        for (var i = 0; i < 4; i++) {
          await store.saveNote(
            Note(
              id: 'n$i',
              body: lang == 'zh'
                  ? '记录正文第$i段。生活里值得留意的小事，可以慢慢写下来。'
                  : 'Journal $i. A small meaningful moment worth remembering in a busy day.',
              day: app.today.plus(-i),
              habitId: i.isEven ? h.id : null,
            ),
            create: true,
            today: app.today,
          );
        }
        await store.saveReminder(
          HabitReminder(
            habitId: h.id,
            enabled: true,
            minutes: [0, 540, 720, 1200, 1439],
          ),
        );
        await store.preference('font', 'serif');
        await app.load();
        t.view.physicalSize = small
            ? const Size(320, 568)
            : const Size(414, 921);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = small ? 1.6 : 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(t.view.resetViewInsets);
        final boundary = GlobalKey();
        Widget shell(Widget child) => RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: Locale(lang),
            theme: dayPanelTheme(
              small ? Brightness.dark : Brightness.light,
              appearance: const Appearance(font: 'serif'),
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: child,
          ),
        );
        Future<void> capture(String label) async {
          await t.pump();
          await t.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 1.5);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            final f = File(
              '.local/reports/qa02-$lang-${small ? 'small' : 'normal'}-$label.png',
            );
            await f.parent.create(recursive: true);
            await f.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }

        Future<void> show(String label, Widget page) async {
          await t.pumpWidget(const SizedBox());
          await t.pumpWidget(shell(page));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: label);
          await capture(label);
        }

        await show('daily', HomePage(app: app));
        await show('tasks', Scaffold(body: TasksPage(app: app)));
        await show('journal', Scaffold(body: JournalPage(app: app)));
        await show('review', ReviewPage(app: app));
        for (var tab = 0; tab < 4; tab++) {
          await show(
            'statistics-$tab',
            StatisticsPage(app: app, initialTab: tab, habitId: h.id),
          );
        }
        await show('cards', CardCollection(app: app));
        await show('card-details', CardDetails(app: app, day: app.today));
        await show(
          'card-share',
          CardSharePage(
            app: app,
            day: app.today,
            title: lang == 'zh' ? '卡片' : 'Daily card',
          ),
        );
        final s = AppLocalizations.of(t.element(find.byType(CardSharePage)));
        await t.tap(find.byKey(const Key('share-reflection')));
        await t.pumpAndSettle();
        await t.enterText(
          find.byKey(const Key('share-excerpt')),
          List.filled(
            4,
            lang == 'zh'
                ? '心得摘录不会覆盖原来记录。'
                : 'A share excerpt keeps the original safe. ',
          ).join(),
        );
        t.view.viewInsets = const FakeViewPadding(bottom: 220);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(find.text(s.cardSaveImage).hitTestable(), findsOneWidget);
        await capture('card-share-keyboard');
        t.view.resetViewInsets();
        await show('appearance', AppearancePage(app: app));
        if (lang == 'en' && small) {
          final cancel = find.text('Cancel').last;
          final paragraph = t.renderObject<RenderParagraph>(cancel);
          final boxes = paragraph.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 6),
          );
          expect(
            boxes.map((b) => b.top).toSet().length,
            1,
            reason: 'Appearance Cancel must not split mid-word',
          );
        }
        await show('backup', BackupPage(app: app));
        await show('reminders', RemindersPage(app: app));
        await show(
          'reminder-editor',
          Scaffold(
            body: ReminderEditor(app: app, habit: h),
          ),
        );
        if (lang == 'en' && small) {
          final paragraph = t.renderObject<RenderParagraph>(
            find.text('Cancel').last,
          );
          final boxes = paragraph.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 6),
          );
          expect(
            boxes.map((b) => b.top).toSet().length,
            1,
            reason: 'Reminder Cancel must not split mid-word',
          );
        }
        expect(
          find.byKey(const Key('save-reminder')).hitTestable(),
          findsOneWidget,
        );
        await show(
          'widget-config',
          WidgetFlow(
            app: app,
            request: {'mode': 'configure', 'widgetId': 8, 'kind': 'habit'},
          ),
        );
        await show('widget-help', WidgetsHelpPage(app: app));
        await t.pumpWidget(const SizedBox());
        app.dispose();
        await store.close();
      });
    }
  }
}
