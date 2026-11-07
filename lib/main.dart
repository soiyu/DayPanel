import 'dart:async';
import 'package:flutter/material.dart';
import 'application/app_controller.dart';
import 'data/app_store.dart';
import 'l10n/app_localizations.dart';
import 'presentation/home.dart';
import 'presentation/theme.dart';
import 'data/reminder_platform.dart';
import 'data/completion_feedback.dart';
import 'presentation/habits.dart';
import 'domain/models.dart';
import 'domain/appearance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'data/widget_platform.dart';
import 'presentation/home_widgets.dart';
export 'application/widget_action_runner.dart' show widgetActionMain;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/OFL-NotoSerifSC.txt',
    );
    yield LicenseEntryWithLineBreaks(['Noto Serif SC'], license);
  });
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<AppController> future;
  @override
  void initState() {
    super.initState();
    future = initialize();
  }

  Future<AppController> initialize() async {
    final store = await AppStore.open();
    final app = AppController(
      store,
      reminderPlatform: AndroidReminders(),
      completionFeedback: AndroidCompletionFeedback(),
      widgetPlatform: AndroidWidgets(),
    );
    try {
      await app.load();
      await app.syncReminders();
      await app.syncWidgets();
      return app;
    } catch (_) {
      app.dispose();
      await store.close();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppController>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasData) return DayPanelApp(app: snapshot.data!);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dayPanelTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Center(
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context).storageError),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () =>
                                  setState(() => future = initialize()),
                              child: Text(AppLocalizations.of(context).retry),
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class DayPanelApp extends StatefulWidget {
  const DayPanelApp({super.key, required this.app});
  final AppController app;
  @override
  State<DayPanelApp> createState() => _DayPanelAppState();
}

class _DayPanelAppState extends State<DayPanelApp> with WidgetsBindingObserver {
  final navigatorKey = GlobalKey<NavigatorState>();
  AppController get app => widget.app;
  bool opening = false;
  Map<String, Object?>? widgetRequest;
  bool widgetLaunchReady = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    app.reminderPlatform?.onOpen(openReminder);
    final updates = app.widgetPlatform;
    if (updates is WidgetUpdates) {
      (updates as WidgetUpdates).onChanged(refreshForeground);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        widgetRequest = await app.widgetPlatform?.launch();
      } catch (_) {
        widgetRequest = {'mode': 'stale'};
      }
      if (mounted) setState(() => widgetLaunchReady = true);
      if (widgetRequest == null) openReminder();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    app.reminderPlatform?.onOpen(() {});
    final updates = app.widgetPlatform;
    if (updates is WidgetUpdates) (updates as WidgetUpdates).onChanged(() {});
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshForeground();
    }
  }

  Future<void> refreshForeground() async {
    if (app.busy || app.closing) return;
    try {
      await app.load();
      await app.syncReminders();
      await app.syncWidgets();
      if (widgetRequest == null) await openReminder();
    } catch (_) {
      /* The existing error/retry UI remains available. */
    }
  }

  Future<void> openReminder() async {
    if (opening || app.reminderPlatform == null) return;
    opening = true;
    try {
      final request = await app.reminderPlatform!.takeOpenRequest();
      if (request == null || !mounted) return;
      if (app.busy) return;
      await app.load();
      if (request['generation'] != app.generation) return;
      final matches = app.habits.where(
        (h) => h.id == request['id'] && !h.archived,
      );
      if (matches.isEmpty) return;
      final h = matches.first;
      final day = Day.parse(request['day'] as String);
      if (day != app.today) return;
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      nav.popUntil((route) => route.isFirst);
      app.select(day);
      unawaited(
        nav.push(
          MaterialPageRoute<void>(
            builder: (context) => HabitDetails(
              app: app,
              id: h.id,
              logOnOpen: h.kind == HabitKind.quantity,
            ),
          ),
        ),
      );
    } catch (_) {
      /* Invalid/stale notification opens the app without writing data. */
    } finally {
      opening = false;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) => MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DayPanel',
      debugShowCheckedModeBanner: false,
      theme: dayPanelTheme(
        Brightness.light,
        appearance: Appearance.fromSettings(app.preferences),
      ),
      darkTheme: dayPanelTheme(
        Brightness.dark,
        appearance: Appearance.fromSettings(app.preferences),
      ),
      themeMode: switch (app.preferences['theme']) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      },
      locale: {'en', 'zh'}.contains(app.preferences['locale'])
          ? Locale(app.preferences['locale']!)
          : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: !widgetLaunchReady && app.widgetPlatform != null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : widgetRequest != null
          ? WidgetFlow(
              app: app,
              request: widgetRequest!,
              release: app.store.close,
            )
          : HomePage(app: app),
    ),
  );
}
