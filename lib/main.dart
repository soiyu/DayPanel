import 'package:flutter/material.dart';
import 'application/app_controller.dart';
import 'data/app_store.dart';
import 'l10n/app_localizations.dart';
import 'presentation/home.dart';
import 'presentation/theme.dart';

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
    final app = AppController(store);
    try {
      await app.load();
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

class DayPanelApp extends StatelessWidget {
  const DayPanelApp({super.key, required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) => MaterialApp(
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
