import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/document_files.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/main.dart';
import 'package:daypanel/presentation/backup_page.dart';
import 'package:daypanel/presentation/habits.dart';
import 'package:daypanel/presentation/organization.dart';
import 'package:daypanel/presentation/theme.dart';

class MemoryDocuments implements DocumentFiles {
  Uint8List? source, saved;
  bool allowSave = true;
  @override
  Future<Uint8List?> pick() async => source;
  @override
  Future<bool> save(Uint8List bytes, String name) async {
    if (allowSave) saved = bytes;
    return allowSave;
  }
}

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(store, clock: () => DateTime(2026, 11, 5));
    await app.load();
  });
  tearDown(() async {
    app.dispose();
    await store.close();
  });
  Widget shell(Widget child, {String locale = 'en', bool dark = false}) =>
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: dayPanelTheme(dark ? Brightness.dark : Brightness.light),
        home: child,
      );

  testWidgets(
    'backup file preview requires confirmation; restore and rollback refresh real data',
    (tester) async {
      await store.saveTask(
        const SmallTask(id: 't', title: 'From backup'),
        create: true,
      );
      final backup = await store.exportSnapshot();
      await store.saveTask(const SmallTask(id: 't', title: 'Current task'));
      await app.load();
      final files = MemoryDocuments()..source = backup.encode();
      await tester.pumpWidget(shell(BackupPage(app: app, files: files)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('import-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-backup')));
      await tester.pumpAndSettle();
      expect(find.text('Review this backup'), findsOneWidget);
      expect((await store.tasks()).single.title, 'Current task');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await store.tasks()).single.title, 'Current task');
      await tester.tap(find.byKey(const Key('import-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore & replace'));
      await tester.pumpAndSettle();
      expect(app.tasks.single.title, 'From backup');
      await tester.scrollUntilVisible(
        find.byKey(const Key('rollback-backup')),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rollback-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to previous data').last);
      await tester.pumpAndSettle();
      expect(app.tasks.single.title, 'Current task');
      expect(await store.recoverySnapshot(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'cached recovery cannot replace a newer generation after another restore',
    (tester) async {
      await store.saveTask(
        const SmallTask(id: 't', title: 'Original'),
        create: true,
      );
      final a = await store.exportSnapshot();
      await store.saveTask(
        const SmallTask(id: 't', title: 'Before first restore'),
      );
      await app.load();
      await app.run(() => store.restoreSnapshot(a));
      await tester.pumpWidget(
        shell(BackupPage(app: app, files: MemoryDocuments())),
      );
      await tester.pumpAndSettle();
      await store.saveTask(const SmallTask(id: 't', title: 'New current'));
      final newer = await store.exportSnapshot();
      await app.run(() => store.restoreSnapshot(newer));
      await tester.scrollUntilVisible(
        find.byKey(const Key('rollback-backup')),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rollback-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to previous data').last);
      await tester.pumpAndSettle();
      expect((await store.tasks()).single.title, 'New current');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'cancelled and invalid file selection preserve current content; export is complete',
    (tester) async {
      await store.saveNote(
        Note(id: 'n', body: 'Saved journal', day: app.today),
        create: true,
      );
      await app.load();
      final files = MemoryDocuments();
      await tester.pumpWidget(shell(BackupPage(app: app, files: files)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-backup')));
      await tester.pumpAndSettle();
      expect(app.notes.single.body, 'Saved journal');
      files.source = Uint8List.fromList([1, 2, 3]);
      await tester.tap(find.byKey(const Key('import-backup')));
      await tester.pumpAndSettle();
      expect(await store.generation(), 0);
      expect(app.notes.single.body, 'Saved journal');
      await tester.ensureVisible(find.byKey(const Key('export-backup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('export-backup')));
      await tester.pumpAndSettle();
      expect(BackupSnapshot.decode(files.saved!).count('notes'), 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'weekly habit editor persists rule and shows flexible group instead of daily obligation',
    (tester) async {
      await tester.pumpWidget(DayPanelApp(app: app));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-entry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('custom-habit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('entry-title')), 'Walk');
      await tester.ensureVisible(find.text('Weekly target'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly target'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('schedule-number')), '3');
      await tester.tap(find.byKey(const Key('save-entry')));
      await tester.pumpAndSettle();
      final created = app.habits.single;
      expect(created.schedule, ScheduleKind.weekly);
      expect(created.weeklyGoal, 3);
      expect(app.planned, isEmpty);
      expect(app.entries, isEmpty);
      final detail = tester.widget<HabitDetails>(find.byType(HabitDetails));
      expect(detail.id, created.id);
      expect(detail.initialDay, app.today);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HabitDetails), findsNothing);
      expect(app.planned, isEmpty);
      expect(find.text('Flexible this week'), findsOneWidget);
      expect(find.byKey(Key('habit-action-${created.id}')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'group create and reorder arrows persist without deleting records',
    (tester) async {
      await store.saveHabit(
        Habit(
          id: 'a',
          title: 'First',
          kind: HabitKind.check,
          startDay: app.today,
        ),
        create: true,
      );
      await store.saveHabit(
        Habit(
          id: 'b',
          title: 'Second',
          kind: HabitKind.check,
          startDay: app.today,
        ),
        create: true,
      );
      await app.load();
      await tester.pumpWidget(shell(GroupsPage(app: app)));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('group-name')), 'Health');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(app.groups.single.name, 'Health');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(shell(HabitOrderPage(app: app)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Move down').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(app.habits.map((h) => h.id).toList(), ['b', 'a']);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final locale in ['en', 'zh']) {
    testWidgets(
      '$locale backup preview and group sorting fit 320dp and 160% text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await store.saveHabit(
          Habit(
            id: 'h',
            title: 'Long title with a few words 测试习惯',
            kind: HabitKind.check,
            startDay: app.today,
          ),
          create: true,
        );
        await app.load();
        final files = MemoryDocuments()
          ..source = (await store.exportSnapshot()).encode();
        await tester.pumpWidget(
          shell(
            BackupPage(app: app, files: files),
            locale: locale,
            dark: true,
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('import-backup')),
          180,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('import-backup')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(locale == 'zh' ? '取消' : 'Cancel'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          shell(HabitOrderPage(app: app), locale: locale, dark: true),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
