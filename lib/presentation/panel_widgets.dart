import 'dart:convert';
import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../data/widget_platform.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'plus_page.dart';
import 'habits.dart';
import 'tasks.dart';

class PanelWidgetPage extends StatefulWidget {
  const PanelWidgetPage({
    super.key,
    required this.app,
    this.request,
    this.release,
  });
  final AppController app;
  final Map<String, Object?>? request;
  final Future<void> Function()? release;
  @override
  State<PanelWidgetPage> createState() => _PanelWidgetPageState();
}

class _PanelWidgetPageState extends State<PanelWidgetPage> {
  AppController get app => widget.app;
  late final epoch = app.generation;
  final selected = <String>[];
  bool saving = false;
  String? message;
  bool get viewing => widget.request?['mode'] == 'panelView';
  bool get hosted => widget.request != null;
  @override
  void initState() {
    super.initState();
    if (widget.request?['generation'] == epoch) {
      try {
        for (final row in jsonDecode(widget.request!['id'] as String) as List) {
          selected.add('${row['kind']}:${row['id']}');
        }
      } catch (_) {}
    }
  }

  Future<void> close() async {
    if (hosted) {
      await widget.release?.call();
      await app.widgetPlatform?.close();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  String encode() => jsonEncode([
    for (final key in selected)
      {
        'kind': key.substring(0, key.indexOf(':')),
        'id': key.substring(key.indexOf(':') + 1),
      },
  ]);
  Future<void> save() async {
    if (saving || selected.isEmpty) return;
    final s = AppLocalizations.of(context);
    if (!await requirePlus(context, app) || !mounted) return;
    setState(() => saving = true);
    try {
      if (epoch != await app.store.generation()) throw StateError('Changed');
      final platform = app.widgetPlatform;
      if (hosted) {
        await platform!.configure(
          widget.request!['widgetId'] as int,
          encode(),
          epoch,
        );
        await close();
      } else if (platform is WidgetPinning) {
        final pin = platform as WidgetPinning;
        final ok = await pin.pin('panel', encode(), epoch);
        if (mounted) {
          setState(
            () => message = ok ? s.widgetPinRequested : s.widgetPinUnavailable,
          );
        }
      } else {
        if (mounted) setState(() => message = s.widgetPinUnavailable);
      }
    } catch (_) {
      if (mounted) setState(() => message = s.widgetPinFailed);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: app, builder: _body);

  Widget _body(BuildContext context, Widget? child) {
    final s = AppLocalizations.of(context);
    final choices = <String, String>{
      for (final h in app.habits.where((h) => !h.archived))
        'habit:${h.id}': h.title,
      for (final t in app.tasks.where((t) => !t.archived))
        'task:${t.id}': t.title,
    };
    return PopScope(
      canPop: !hosted && !saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !saving) close();
      },
      child: AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.panelTitle),
            automaticallyImplyLeading: !hosted,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (epoch != app.generation)
                        Text(s.recordChanged)
                      else if (viewing) ...[
                        for (final key in selected) ...[
                          if (key.startsWith('habit:'))
                            for (final h in app.habits.where(
                              (h) => h.id == key.substring(6),
                            ))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: HabitTile(
                                  app: app,
                                  habit: h,
                                  day: app.today,
                                ),
                              ),
                          if (key.startsWith('task:'))
                            for (final t in app.tasks.where(
                              (t) => t.id == key.substring(5),
                            ))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TaskTile(app: app, task: t),
                              ),
                        ],
                      ] else ...[
                        Text(
                          s.panelChoose,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < selected.length; i++)
                          SoftPanel(
                            padding: const EdgeInsets.all(4),
                            child: SettingRow(
                              icon: Icons.drag_handle,
                              title:
                                  '${i + 1}. ${choices[selected[i]] ?? s.widgetExpired}',
                              trailing: IconButton(
                                tooltip: s.moveUp,
                                icon: const Icon(Icons.keyboard_arrow_up),
                                onPressed: saving || i == 0
                                    ? null
                                    : () => setState(() {
                                        final item = selected.removeAt(i);
                                        selected.insert(i - 1, item);
                                      }),
                              ),
                              onTap: null,
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (choices.isEmpty) Text(s.widgetEmpty),
                        for (final choice in choices.entries)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              choice.value,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              choice.key.startsWith('habit:')
                                  ? s.privateHabit
                                  : s.tasks,
                            ),
                            value: selected.contains(choice.key),
                            onChanged:
                                saving ||
                                    (selected.length >= 4 &&
                                        !selected.contains(choice.key))
                                ? null
                                : (v) => setState(() {
                                    if (v == true) {
                                      if (selected.length < 4) {
                                        selected.add(choice.key);
                                      }
                                    } else {
                                      selected.remove(choice.key);
                                    }
                                  }),
                          ),
                      ],
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(message!),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppAction(
                          label: s.cancel,
                          onTap: saving ? null : close,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!viewing)
                        Expanded(
                          child: AppAction(
                            key: const Key('panel-save'),
                            label: hosted ? s.save : s.panelAdd,
                            primary: true,
                            busy: saving,
                            onTap:
                                saving ||
                                    selected.isEmpty ||
                                    epoch != app.generation
                                ? null
                                : save,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
