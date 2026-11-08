import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../data/widget_platform.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'editors.dart';
import 'habits.dart';
import 'tasks.dart';
import 'refined_components.dart';

class WidgetFlow extends StatefulWidget {
  const WidgetFlow({
    super.key,
    required this.app,
    required this.request,
    this.release,
  });
  final AppController app;
  final Map<String, Object?> request;
  final Future<void> Function()? release;
  @override
  State<WidgetFlow> createState() => _WidgetFlowState();
}

class _WidgetFlowState extends State<WidgetFlow> {
  AppController get app => widget.app;
  late final int epoch;
  String? selected;
  bool busy = false;
  bool failed = false;
  bool get configuring => widget.request['mode'] == 'configure';

  @override
  void initState() {
    super.initState();
    epoch = app.generation;
    if (widget.request['generation'] == epoch) {
      selected = widget.request['id'] as String?;
    }
    if (!configuring) {
      WidgetsBinding.instance.addPostFrameCallback((_) => open());
    }
  }

  Future<void> close() async {
    if (app.closing) return;
    app.closing = true;
    await widget.release?.call();
    await app.widgetPlatform?.close();
  }

  Future<void> openApp() async {
    if (app.closing) return;
    app.closing = true;
    await widget.release?.call();
    await app.widgetPlatform?.openApp();
  }

  Future<bool> valid() async =>
      app.generation == epoch &&
      await app.widgetPlatform!.validate(widget.request);

  Future<void> open() async {
    try {
      if (!await valid() || !mounted) {
        throw StateError('Stale widget');
      }
      final request = widget.request;
      final id = request['id'] as String;
      final kind = request['kind'] as String;
      final day = Day.parse(request['day'] as String);
      if (request['mode'] == 'complete') {
        setState(() => busy = true);
        final ok = await app.recordFromWidget(
          kind: kind,
          id: id,
          day: day,
          epoch: epoch,
        );
        if (!ok) throw StateError('Save failed');
        await close();
      } else if (request['mode'] == 'quantity') {
        final habit = app.habits.firstWhere((h) => h.id == id);
        if (!mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          builder: (_) => QuantityEditor(
            app: app,
            habit: habit,
            day: day,
            onSave: (value, revision) async {
              if (!await valid() || day != app.today) {
                if (mounted) setState(() => failed = true);
                await app.syncWidgets();
                return false;
              }
              // The same transaction/achievement path as an in-app quantity save.
              return app.recordHabit(
                habit,
                day,
                value,
                epoch,
                requireToday: true,
                expectedRevision: revision,
              );
            },
          ),
        );
        await close();
      } else if (request['mode'] == 'view') {
        if (!mounted) return;
        app.select(day);
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) {
              if (kind == 'habit') {
                return HabitDetails(app: app, id: id, initialDay: day);
              }
              final task = app.tasks.firstWhere((t) => t.id == id);
              return task.resident
                  ? ResidentTaskPage(app: app, id: id)
                  : OneTimeTaskPage(app: app, id: id);
            },
          ),
        );
        await close();
      } else {
        throw StateError('Unknown action');
      }
    } catch (_) {
      await app.syncWidgets();
      if (mounted) {
        setState(() {
          failed = true;
          busy = false;
        });
      }
    }
  }

  Future<void> save() async {
    if (busy || selected == null) return;
    setState(() => busy = true);
    try {
      if (app.generation != epoch || await app.store.generation() != epoch) {
        throw StateError('Data changed');
      }
      await app.widgetPlatform!.configure(
        widget.request['widgetId'] as int,
        selected!,
        epoch,
      );
      await close();
    } catch (_) {
      if (mounted) {
        setState(() {
          failed = true;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final choices = <(String, String, String)>[
      if (widget.request['kind'] == 'habit')
        for (final h in app.habits.where((h) => !h.archived))
          (
            h.id,
            h.title,
            h.kind == HabitKind.count
                ? s.countHabit
                : h.kind.isNumeric
                ? s.quantityHabit
                : s.checkHabit,
          )
      else
        for (final t in app.tasks.where((t) => !t.archived))
          (t.id, t.title, t.resident ? s.residentTask : s.oneTimeTask),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy) close();
      },
      child: AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.widgetsTitle)),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (configuring) ...[
                        Text(
                          s.widgetChoose,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                      ] else
                        SoftPanel(
                          tinted: true,
                          tone: failed ? UiTone.peach : UiTone.violet,
                          child: Column(
                            children: [
                              Icon(
                                failed
                                    ? Icons.info_outline
                                    : Icons.widgets_outlined,
                                size: 32,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                failed
                                    ? s.widgetExpired
                                    : widget.request['mode'] == 'complete'
                                    ? s.widgetSaving
                                    : s.widgetOpening,
                              ),
                            ],
                          ),
                        ),
                      if (failed && configuring)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            s.widgetExpired,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (configuring) ...[
                        const SizedBox(height: 20),
                        if (choices.isEmpty) ...[
                          Text(s.widgetEmpty),
                          const SizedBox(height: 16),
                          AppAction(label: s.widgetOpenApp, onTap: openApp),
                        ],
                        for (final choice in choices)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SoftPanel(
                              padding: EdgeInsets.zero,
                              tinted: selected == choice.$1,
                              child: SettingRow(
                                icon: widget.request['kind'] == 'habit'
                                    ? Icons.spa_outlined
                                    : Icons.task_alt,
                                title: choice.$2,
                                subtitle: choice.$3,
                                trailing: Icon(
                                  selected == choice.$1
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: UiTone.blue.ink(context),
                                ),
                                onTap: busy
                                    ? null
                                    : () =>
                                          setState(() => selected = choice.$1),
                              ),
                            ),
                          ),
                      ],
                      if (busy)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
                EditorFooter(
                  children: [
                    Expanded(
                      child: AppAction(
                        label: configuring ? s.cancel : s.widgetClose,
                        onTap: busy ? null : close,
                      ),
                    ),
                    if (configuring) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppAction(
                          label: s.save,
                          primary: true,
                          busy: busy,
                          onTap: busy || !choices.any((c) => c.$1 == selected)
                              ? null
                              : save,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WidgetsHelpPage extends StatefulWidget {
  const WidgetsHelpPage({super.key, this.app, this.reconnect = false});
  final AppController? app;
  final bool reconnect;
  @override
  State<WidgetsHelpPage> createState() => _WidgetsHelpPageState();
}

class _WidgetsHelpPageState extends State<WidgetsHelpPage> {
  bool? supported;
  bool working = false;
  String? message;
  @override
  void initState() {
    super.initState();
    final platform = widget.app?.widgetPlatform;
    if (platform is WidgetPinning) {
      (platform as WidgetPinning)
          .canPin()
          .then((value) {
            if (mounted) setState(() => supported = value);
          })
          .catchError((Object _) {
            if (mounted) setState(() => supported = false);
          });
    } else {
      supported = false;
    }
  }

  Future<void> choose() async {
    final app = widget.app;
    final platform = app?.widgetPlatform;
    if (app == null || platform is! WidgetPinning || working) return;
    final epoch = app.generation;
    final s = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SheetFrame(
        title: s.widgetPinSelect,
        subtitle: s.widgetChooseHint,
        icon: Icons.widgets_outlined,
        tone: UiTone.violet,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!app.habits.any((h) => !h.archived) &&
                !app.tasks.any((t) => !t.archived))
              Text(s.widgetPinEmpty),
            for (final h in app.habits.where((h) => !h.archived))
              SettingRow(
                key: Key('pin-habit-${h.id}'),
                icon: Icons.spa_outlined,
                title: h.title,
                subtitle: s.habit,
                onTap: () => Navigator.pop(ctx, ('habit', h.id)),
              ),
            for (final t in app.tasks.where((t) => !t.archived))
              SettingRow(
                key: Key('pin-task-${t.id}'),
                icon: Icons.check_circle_outline,
                title: t.title,
                subtitle: t.resident ? s.residentTask : s.oneTimeTask,
                onTap: () => Navigator.pop(ctx, ('task', t.id)),
              ),
          ],
        ),
        footer: AppAction(label: s.cancel, onTap: () => Navigator.pop(ctx)),
      ),
    );
    if (selected == null || !mounted) return;
    if (epoch != app.generation) {
      setState(() => message = s.widgetPinFailed);
      return;
    }
    setState(() {
      working = true;
      message = null;
    });
    try {
      final requested = await (platform as WidgetPinning).pin(
        selected.$1,
        selected.$2,
        epoch,
      );
      if (mounted) {
        setState(
          () => message = requested
              ? s.widgetPinRequested
              : s.widgetPinUnavailable,
        );
      }
    } catch (_) {
      if (mounted) setState(() => message = s.widgetPinFailed);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.widgetsHelpTitle)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (supported == true && !widget.reconnect) ...[
              AppAction(
                key: const Key('pin-widget'),
                label: s.widgetAddTitle,
                icon: Icons.add_to_home_screen_rounded,
                primary: true,
                busy: working,
                onTap: working ? null : choose,
              ),
              const SizedBox(height: 12),
              Text(s.widgetChooseHint),
              const SizedBox(height: 16),
            ],
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(message!, key: const Key('pin-result')),
              ),
            if (supported == false && widget.app != null && !widget.reconnect)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(s.widgetPinUnavailable),
              ),
            SoftPanel(
              tone: UiTone.violet,
              tinted: true,
              child: Text(
                widget.reconnect ? s.widgetReconnectHelp : s.widgetHelp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
