import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'habit_icon.dart';
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
            onSave: (value) async {
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
              if (kind == 'habit') return HabitDetails(app: app, id: id);
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
            h.kind == HabitKind.quantity ? s.quantityHabit : s.checkHabit,
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
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.uiWidgetChooseHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (selected != null &&
                            choices.any((c) => c.$1 == selected)) ...[
                          const SizedBox(height: 18),
                          SoftPanel(
                            tinted: true,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                if (widget.request['kind'] == 'habit')
                                  HabitIcon(
                                    app.habits
                                        .firstWhere((h) => h.id == selected)
                                        .icon,
                                    size: 48,
                                    color: app.habits
                                        .firstWhere((h) => h.id == selected)
                                        .color,
                                    frame: app.habits
                                        .firstWhere((h) => h.id == selected)
                                        .frame,
                                  )
                                else
                                  const ToneIcon(
                                    Icons.checklist_rounded,
                                    tone: UiTone.peach,
                                    size: 42,
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        choices
                                            .firstWhere((c) => c.$1 == selected)
                                            .$2,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        s.widgetConfigHint,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class WidgetsHelpPage extends StatelessWidget {
  const WidgetsHelpPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.widgetsTitle)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SoftPanel(
              tone: UiTone.violet,
              tinted: true,
              child: Text(s.widgetHelp),
            ),
          ],
        ),
      ),
    );
  }
}
