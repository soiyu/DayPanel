import 'dart:async';
import 'package:flutter/material.dart';
import 'application/app_controller.dart';
import 'data/app_store.dart';
import 'l10n/app_localizations.dart';
import 'presentation/home.dart';
import 'presentation/theme.dart';
import 'data/reminder_platform.dart';
import 'presentation/habits.dart';
import 'domain/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    final app = AppController(store, reminderPlatform: AndroidReminders());
    try {
      await app.load();
      await app.syncReminders();
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    app.reminderPlatform?.onOpen(openReminder);
    WidgetsBinding.instance.addPostFrameCallback((_) => openReminder());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    app.reminderPlatform?.onOpen(() {});
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      app.syncReminders();
      openReminder();
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
      theme: dayPanelTheme(Brightness.light),
      darkTheme: dayPanelTheme(Brightness.dark),
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
      home: HomePage(app: app),
    ),
  );
}
