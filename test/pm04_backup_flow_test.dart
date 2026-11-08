import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/document_files.dart';
import 'package:daypanel/data/widget_platform.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/backup_page.dart';
import 'package:daypanel/presentation/components.dart';
import 'package:daypanel/presentation/home.dart';
import 'package:daypanel/presentation/home_widgets.dart';
import 'package:daypanel/presentation/theme.dart';

class _Files implements DocumentFiles {
  Uint8List? picked;
  bool saved = false;
  @override
  Future<Uint8List?> pick() async => picked;
  @override
  Future<bool> save(Uint8List bytes, String name) async => saved;
}

class _Widgets implements WidgetPlatform, WidgetPinning {
  bool supported = true;
  bool bound = false;
  int pinRequests = 0;
  @override
  Future<bool> canPin() async => supported;
  @override
  Future<bool> hasWidgets() async => bound;
  @override
  Future<bool> pin(String kind, String id, int generation) async {
    pinRequests++;
    return true;
  }

  @override
  Future<void> refresh() async {}
  @override
  Future<Map<String, Object?>?> launch() async => null;
  @override
  Future<bool> validate(Map<String, Object?> request) async => false;
  @override
  Future<void> configure(int widgetId, String id, int generation) async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> openApp() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late _Widgets widgets;
  late Uint8List snapshot;
  final today = Day.parse('2026-11-08');
  const documents = MethodChannel('app.daypanel.next/documents');
  int? exportedAt;
  bool saveAllowed = false;
  int saves = 0;

  setUp(() async {
    exportedAt = null;
    saveAllowed = false;
    saves = 0;
    widgets = _Widgets();
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    app = AppController(
      store,
      clock: () => today.date,
      widgetPlatform: widgets,
    );
    await store.saveHabit(
      Habit(
        id: 'h',
        title: 'Read a page',
        kind: HabitKind.check,
        startDay: today.plus(-4),
      ),
      create: true,
    );
    await app.load();
    snapshot = (await store.exportSnapshot()).encode();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(documents, (call) async {
          switch (call.method) {
            case 'pick':
              return snapshot;
            case 'lastExport':
              return exportedAt;
            case 'save':
              saves++;
              if (saveAllowed) {
                exportedAt = DateTime(
                  2026,
                  11,
                  8,
                  12,
                  30,
                ).millisecondsSinceEpoch;
              }
              return saveAllowed;
            default:
              throw MissingPluginException();
          }
        });
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(documents, null);
    app.dispose();
    await store.close();
  });
  Widget shell(Widget child) => MaterialApp(
    locale: const Locale('en'),
    theme: dayPanelTheme(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  Future<void> tap(WidgetTester t, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        finder,
        180,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(t.element(finder), alignment: .4);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  Widget launcher({DocumentFiles? files, VoidCallback? onReturnToday}) => shell(
    Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => BackupPage(
                app: app,
                files: files,
                onReturnToday: onReturnToday,
              ),
            ),
          ),
          child: const Text('Open backup'),
        ),
      ),
    ),
  );
  Future<void> restore(WidgetTester t) async {
    await tap(t, find.byKey(const Key('import-backup')));
    await tap(t, find.text('Restore & replace'));
  }

  testWidgets(
    'restore cancellation preserves data and never calls return callback',
    (t) async {
      var returned = 0;
      final files = _Files()..picked = snapshot;
      await store.setRecord('h', today, 1000, today: today);
      await app.load();
      final generation = app.generation;
      await t.pumpWidget(
        launcher(files: files, onReturnToday: () => returned++),
      );
      await tap(t, find.text('Open backup'));
      await tap(t, find.byKey(const Key('import-backup')));
      await tap(t, find.text('Cancel').last);
      expect(returned, 0);
      expect(app.generation, generation);
      expect(app.entries.single.value, 1000);
      expect(find.text('Next steps'), findsNothing);
      expect(find.byType(BackupPage), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'successful restore Today calls host callback and returns to first route',
    (t) async {
      var returned = 0;
      final files = _Files()..picked = snapshot;
      app.select(today.plus(-2));
      await store.setRecord('h', today, 1000, today: today);
      await app.load();
      final generation = app.generation;
      await t.pumpWidget(
        launcher(files: files, onReturnToday: () => returned++),
      );
      await tap(t, find.text('Open backup'));
      await restore(t);
      expect(app.generation, generation + 1);
      expect(app.entries, isEmpty);
      expect(await store.recoverySnapshot(), isNotNull);
      expect(find.text('Next steps'), findsOneWidget);
      expect(find.text('Check reminders and permissions'), findsNothing);
      expect(find.text('Reconnect home screen widgets'), findsNothing);
      await tap(t, find.text('Today'));
      expect(returned, 1);
      expect(app.selectedDay, today);
      expect(find.byType(BackupPage), findsNothing);
      expect(find.text('Open backup'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'restore Today returns actual HomePage from Mine tab to daily tab',
    (t) async {
      app.select(today.plus(-3));
      await t.pumpWidget(shell(HomePage(app: app)));
      await t.pumpAndSettle();
      await tap(t, find.byKey(const Key('tab-3')));
      expect(t.widget<GlassNavigation>(find.byType(GlassNavigation)).index, 3);
      await tap(t, find.byKey(const Key('settings-backup')));
      await restore(t);
      await tap(t, find.text('Today'));
      expect(find.byType(BackupPage), findsNothing);
      expect(t.widget<GlassNavigation>(find.byType(GlassNavigation)).index, 0);
      expect(app.selectedDay, today);
      expect(find.byKey(const Key('daily-date')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'restore with existing widgets opens reconnect help without pinning duplicates',
    (t) async {
      widgets.bound = true;
      await t.pumpWidget(launcher());
      await tap(t, find.text('Open backup'));
      await restore(t);
      await tap(t, find.text('Reconnect home screen widgets'));
      final help = t.widget<WidgetsHelpPage>(find.byType(WidgetsHelpPage));
      expect(help.reconnect, isTrue);
      expect(find.byKey(const Key('pin-widget')), findsNothing);
      expect(find.textContaining('each existing widget'), findsOneWidget);
      expect(widgets.pinRequests, 0);
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(shell(WidgetsHelpPage(app: app)));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('pin-widget')), findsOneWidget);
      expect(widgets.pinRequests, 0);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'cancelled export does not invent success and successful export is visible after reopening',
    (t) async {
      await t.pumpWidget(launcher());
      await tap(t, find.text('Open backup'));
      expect(
        find.text('No successful export on this device yet'),
        findsOneWidget,
      );
      await tap(t, find.byKey(const Key('export-backup')));
      expect(saves, 1);
      expect(exportedAt, isNull);
      expect(find.text('Backup saved'), findsNothing);
      expect(
        find.text('No successful export on this device yet'),
        findsOneWidget,
      );
      saveAllowed = true;
      await tap(t, find.byKey(const Key('export-backup')));
      expect(saves, 2);
      expect(
        find.textContaining('Last successful export on this device'),
        findsOneWidget,
      );
      expect(find.text('Backup saved'), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      await tap(t, find.text('Open backup'));
      expect(
        find.textContaining('Last successful export on this device'),
        findsOneWidget,
      );
      expect(find.text('Backup saved'), findsNothing);
      expect(find.textContaining('This records a past export'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
}
