import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/document_files.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/appearance.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/achievements.dart';
import 'package:daypanel/presentation/appearance.dart';
import 'package:daypanel/presentation/backup_page.dart';
import 'package:daypanel/presentation/card_share.dart';
import 'package:daypanel/presentation/journal.dart';
import 'package:daypanel/presentation/review.dart';
import 'package:daypanel/presentation/statistics.dart';
import 'package:daypanel/presentation/theme.dart';

class QaDocuments implements DocumentFiles {
  Uint8List? selected;
  bool allowSave = false;
  final exports = <Uint8List>[];
  @override
  Future<Uint8List?> pick() async => selected;
  @override
  Future<bool> save(Uint8List bytes, String name) async {
    if (allowSave) exports.add(bytes);
    return allowSave;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final day = Day.parse('2026-11-10');
  late AppStore store;
  late AppController app;
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifSC.ttf');
    await (FontLoader('Roboto')..addFont(Future.value(font))).load();
    await (FontLoader('Ahem')..addFont(Future.value(font))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('NotoSerifSC')..addFont(Future.value(font))).load();
  });
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => day.date);
    await store.saveHabit(
      Habit(
        id: 'h',
        title: 'Read a chapter 阅读一章',
        kind: HabitKind.check,
        startDay: day.plus(-40),
      ),
      create: true,
      today: day,
    );
    await store.saveHabit(
      Habit(
        id: 'q',
        title: 'Long reading title 用很长的名称核对数量统计标签和换行',
        kind: HabitKind.quantity,
        startDay: day.plus(-40),
        target: 10000,
        unit: 'pages',
      ),
      create: true,
      today: day,
    );
    await store.setRecord('h', day.plus(-2), 1000, today: day);
    await store.setRecord('q', day.plus(-2), 0, today: day);
    await store.setRecord('q', day.plus(-1), 5000, today: day);
    await store.setRecord('h', day, 1000, today: day);
    await store.setRecord('q', day, 10000, today: day);
    await store.saveNote(
      Note(
        id: 'old',
        body: 'Unique moonriver 星河关键词 old month note',
        day: Day.parse('2026-10-03'),
        habitId: 'q',
      ),
      create: true,
      today: day,
    );
    await store.saveNote(
      Note(
        id: 'note',
        body:
            'A readable entry. 今天读到一段值得保留的话。\n${List.filled(8, 'A longer paragraph 长正文不会自动完成习惯。').join('\n')}',
        day: day,
      ),
      create: true,
      today: day,
    );
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  for (final lang in ['zh', 'en']) {
    for (final narrow in [false, true]) {
      final size = narrow ? const Size(320, 568) : const Size(414, 921);
      final scale = narrow ? 1.6 : 1.0;
      final tag = '$lang-${narrow ? 'short-large' : 'long-normal'}';
      final capture = GlobalKey();
      Widget shell(Widget child) => MaterialApp(
        locale: Locale(lang),
        theme: dayPanelTheme(
          narrow ? Brightness.dark : Brightness.light,
          appearance: const Appearance(font: 'serif'),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (c, w) => RepaintBoundary(key: capture, child: w!),
        home: child,
      );
      Future<void> sizeUp(WidgetTester t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetViewInsets);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      }

      Future<void> shot(WidgetTester t, String name) async {
        await t.pump();
        await t.pump(const Duration(milliseconds: 16));
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await t.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final file = File('.local/reports/qa02-content-$tag-$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
        });
      }

      Future<void> tap(WidgetTester t, Finder f) async {
        if (f.evaluate().isEmpty) {
          final vertical = find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first;
          for (var i = 0; i < 40; i++) {
            final pos = t.state<ScrollableState>(vertical).position;
            if (pos.pixels <= pos.minScrollExtent) break;
            await t.drag(vertical, const Offset(0, 400));
            await t.pumpAndSettle();
          }
          await t.scrollUntilVisible(
            f,
            200,
            scrollable: vertical,
            maxScrolls: 80,
          );
        }
        await Scrollable.ensureVisible(t.element(f), alignment: .4);
        await t.pumpAndSettle();
        expect(f.hitTestable(), findsOneWidget);
        await t.tap(f);
        await t.pumpAndSettle();
        await t.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pumpAndSettle();
      }

      AppLocalizations strings(WidgetTester t) =>
          AppLocalizations.of(t.element(find.byType(Scaffold).last));
      testWidgets('$tag H search range and editor cancel/save with keyboard', (
        t,
      ) async {
        await sizeUp(t);
        await t.pumpWidget(shell(Scaffold(body: JournalPage(app: app))));
        await t.pumpAndSettle();
        final s = strings(t);
        await shot(t, 'journal-first');
        await t.enterText(find.byKey(const Key('note-search')), 'moonriver');
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        expect(app.visibleNotes, isEmpty);
        await shot(t, 'journal-search-empty');
        await tap(t, find.text(s.pmSearchAllMonths));
        expect(app.journalQuery.month, isNull);
        expect(app.journalQuery.text, 'moonriver');
        expect(app.visibleNotes.single.id, 'old');
        await tap(t, find.text(app.visibleNotes.single.body));
        await t.enterText(
          find.byKey(const Key('entry-title')),
          'Edited but cancelled 取消这次修改',
        );
        if (narrow) t.view.viewInsets = const FakeViewPadding(bottom: 200);
        await t.pumpAndSettle();
        expect(
          find.byKey(const Key('save-entry')).hitTestable(),
          findsOneWidget,
        );
        await shot(t, 'note-keyboard');
        await tap(t, find.text(s.cancel).last);
        t.view.resetViewInsets();
        await t.pumpAndSettle();
        expect(
          (await store.notes()).firstWhere((n) => n.id == 'old').body,
          contains('moonriver'),
        );
        await tap(t, find.text(app.visibleNotes.single.body));
        await t.enterText(
          find.byKey(const Key('entry-title')),
          'moonriver edited and saved 已保存',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        await tap(t, find.byKey(const Key('save-entry')));
        expect(
          (await store.notes()).firstWhere((n) => n.id == 'old').body,
          'moonriver edited and saved 已保存',
        );
        expect(app.entries.length, 5);
        expect(t.takeException(), isNull);
      });
      testWidgets(
        '$tag I actual statistics routes preserve dates and allow confirmed correction',
        (t) async {
          await sizeUp(t);
          await t.pumpWidget(
            shell(StatisticsPage(app: app, initialDay: day, habitId: 'q')),
          );
          await t.pumpAndSettle();
          final s = strings(t);
          await shot(t, 'table');
          await tap(t, find.byKey(Key('matrix-q-${day.key}')));
          await t.enterText(find.byKey(const Key('quantity-input')), '8');
          if (narrow) t.view.viewInsets = const FakeViewPadding(bottom: 200);
          await t.pumpAndSettle();
          await shot(t, 'matrix-input');
          await tap(t, find.text(s.cancel).last);
          t.view.resetViewInsets();
          expect(
            app.value(app.habits.firstWhere((h) => h.id == 'q'), day),
            10000,
          );
          await tap(t, find.byKey(const Key('statistics-tab-1')));
          await tap(t, find.byKey(const Key('statistics-range-7')));
          await tap(t, find.byKey(const Key('quantity-statistics')));
          await shot(t, 'quantity-stats');
          expect(find.byKey(const Key('quantity-statistics')), findsOneWidget);
          await tap(t, find.byKey(const Key('statistics-tab-2')));
          await shot(t, 'year-calendar');
          await tap(t, find.byKey(const Key('statistics-tab-3')));
          await shot(t, 'timeline');
          final before = (await store.exportSnapshot()).tables;
          await t.pumpWidget(shell(ReviewPage(app: app)));
          await t.pumpAndSettle();
          await tap(t, find.byKey(Key('review-day-${day.key}')));
          expect(
            t.widget<DayHistoryPage>(find.byType(DayHistoryPage)).day,
            day,
          );
          await shot(t, 'day-history');
          expect((await store.exportSnapshot()).tables, before);
          expect(t.takeException(), isNull);
        },
      );
      testWidgets(
        '$tag J earned card reflection and share draft keep data private',
        (t) async {
          await sizeUp(t);
          expect(app.cards.length, 1);
          await t.pumpWidget(shell(CardDetails(app: app, day: day)));
          await t.pumpAndSettle();
          await shot(t, 'card-front');
          await tap(t, find.byKey(const Key('favorite-card')));
          expect(app.cards.single.favorite, isTrue);
          await tap(t, find.byKey(const Key('flip-card')));
          await tap(t, find.byKey(const Key('edit-reflection')));
          await t.enterText(
            find.byKey(const Key('reflection-text')),
            'My private reflection 私人的心得',
          );
          if (narrow) t.view.viewInsets = const FakeViewPadding(bottom: 200);
          await t.pumpAndSettle();
          expect(
            find.byKey(const Key('save-reflection')).hitTestable(),
            findsOneWidget,
          );
          await shot(t, 'reflection-keyboard');
          await tap(t, find.byKey(const Key('save-reflection')));
          t.view.resetViewInsets();
          await t.pumpAndSettle();
          expect(app.cards.single.reflection, 'My private reflection 私人的心得');
          await tap(t, find.byKey(const Key('open-card-share')));
          await shot(t, 'share-private-default');
          expect(
            t
                .widget<SwitchListTile>(find.byKey(const Key('share-names')))
                .value,
            isFalse,
          );
          expect(
            t
                .widget<SwitchListTile>(
                  find.byKey(const Key('share-reflection')),
                )
                .value,
            isFalse,
          );
          await tap(t, find.byKey(const Key('share-reflection')));
          await t.enterText(
            find.byKey(const Key('share-excerpt')),
            'Public excerpt 分享摘录',
          );
          if (narrow) t.view.viewInsets = const FakeViewPadding(bottom: 200);
          await t.pumpAndSettle();
          await shot(t, 'share-keyboard');
          expect(
            find.byKey(const Key('save-card-image')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('share-card-image')).hitTestable(),
            findsOneWidget,
          );
          expect(app.cards.single.reflection, 'My private reflection 私人的心得');
          t.view.resetViewInsets();
          FocusManager.instance.primaryFocus?.unfocus();
          await t.pumpAndSettle();
          await t.tap(
            find.byTooltip(
              MaterialLocalizations.of(
                t.element(find.byType(CardSharePage)),
              ).backButtonTooltip,
            ),
          );
          await t.pumpAndSettle();
          expect(find.byType(CardDetails), findsOneWidget);
          expect(t.takeException(), isNull);
        },
      );
      testWidgets(
        '$tag M appearance preview cancel and save remain reachable',
        (t) async {
          await sizeUp(t);
          Widget launcher() => Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => Navigator.push<void>(
                  c,
                  MaterialPageRoute<void>(
                    builder: (_) => AppearancePage(app: app),
                  ),
                ),
                child: const Text('Open appearance'),
              ),
            ),
          );
          await t.pumpWidget(shell(launcher()));
          await t.pumpAndSettle();
          await tap(t, find.text('Open appearance'));
          final s = strings(t);
          await tap(t, find.byKey(const Key('palette-teal')));
          await tap(t, find.byKey(const Key('font-serif')));
          await shot(t, 'appearance-preview');
          expect(await store.settings(), isEmpty);
          await tap(t, find.text(s.cancel));
          expect(await store.settings(), isEmpty);
          await tap(t, find.text('Open appearance'));
          await tap(t, find.byKey(const Key('palette-violet')));
          await tap(t, find.byKey(const Key('font-serif')));
          await tap(t, find.byKey(const Key('appearance-save')));
          expect(
            Appearance.fromSettings(await store.settings()).palette,
            'violet',
          );
          expect(Appearance.fromSettings(await store.settings()).font, 'serif');
          expect(find.text('Open appearance'), findsOneWidget);
          expect(t.takeException(), isNull);
        },
      );
      testWidgets(
        '$tag N A-B backup preview cancel restore rollback and invalid file',
        (t) async {
          await sizeUp(t);
          final files = QaDocuments();
          final a = await store.exportSnapshot();
          files.selected = a.encode();
          await store.saveNote(
            Note(id: 'markerB', body: 'Restore marker B', day: day),
            create: true,
            today: day,
          );
          await app.load();
          final b = (await store.exportSnapshot()).tables;
          await t.pumpWidget(shell(BackupPage(app: app, files: files)));
          await t.pumpAndSettle();
          final s = strings(t);
          await shot(t, 'backup');
          await tap(t, find.byKey(const Key('export-backup')));
          expect(files.exports, isEmpty);
          files.allowSave = true;
          await tap(t, find.byKey(const Key('export-backup')));
          expect(files.exports.length, 1);
          await tap(t, find.byKey(const Key('import-backup')));
          expect(
            find.text(s.restoreConfirm),
            findsOneWidget,
            reason:
                '${app.error}; picked=${files.selected?.length}; ${t.widgetList<Text>(find.byType(Text)).map((w) => w.data).join(' | ')}',
          );
          await shot(t, 'restore-preview');
          await tap(t, find.text(s.cancel).last);
          expect((await store.exportSnapshot()).tables, b);
          await tap(t, find.byKey(const Key('import-backup')));
          await tap(t, find.text(s.restoreConfirm).last);
          expect((await store.exportSnapshot()).tables, a.tables);
          await shot(t, 'restored-next');
          await tap(t, find.byKey(const Key('rollback-backup')));
          await tap(t, find.text(s.rollbackTitle).last);
          expect((await store.exportSnapshot()).tables, b);
          files.selected = Uint8List.fromList('invalid file'.codeUnits);
          await tap(t, find.byKey(const Key('import-backup')));
          expect((await store.exportSnapshot()).tables, b);
          final invalidMessage = find.text(s.backupInvalid);
          if (invalidMessage.evaluate().isEmpty) {
            await t.scrollUntilVisible(
              invalidMessage,
              160,
              scrollable: find
                  .byWidgetPredicate(
                    (w) =>
                        w is Scrollable &&
                        w.axisDirection == AxisDirection.down,
                  )
                  .first,
              maxScrolls: 40,
            );
          }
          await Scrollable.ensureVisible(
            t.element(invalidMessage),
            alignment: .4,
          );
          await t.pumpAndSettle();
          expect(invalidMessage.hitTestable(), findsOneWidget);
          await shot(t, 'backup-invalid-visible');
          expect(t.takeException(), isNull);
        },
      );
      testWidgets(
        '$tag missing earned-card screen fills width and preserves explanation',
        (t) async {
          await sizeUp(t);
          await t.pumpWidget(shell(CardDetails(app: app, day: day.plus(-7))));
          await t.pumpAndSettle();
          await shot(t, 'missing-card-fixed');
          final s = strings(t);
          final body = find.text(s.cardRestoreHint);
          final rect = t.getRect(body);
          expect(
            rect.left,
            greaterThanOrEqualTo(20),
            reason: 'Missing-card explanation needs horizontal padding',
          );
          expect(rect.right, lessThanOrEqualTo(size.width - 20));
          expect(rect.center.dx, closeTo(size.width / 2, .1));
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
