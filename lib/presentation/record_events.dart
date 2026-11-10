import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../application/app_controller.dart';
import '../data/app_store.dart';
import '../domain/models.dart';
import '../domain/record_event.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'plus_page.dart';

class RecordEventsPage extends StatefulWidget {
  const RecordEventsPage({
    super.key,
    required this.app,
    required this.habitId,
    required this.day,
  });
  final AppController app;
  final String habitId;
  final Day day;
  @override
  State<RecordEventsPage> createState() => _RecordEventsPageState();
}

class _RecordEventsPageState extends State<RecordEventsPage> {
  late final int epoch = widget.app.generation;
  AppController get app => widget.app;
  Future<void> edit(Habit h, [RecordEvent? event]) async {
    if (event == null && !await requirePlus(context, app)) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          RecordEventEditor(app: app, habit: h, day: widget.day, event: event),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final h = app.habits.where((h) => h.id == widget.habitId).firstOrNull;
      final valid = h != null && epoch == app.generation;
      final rows = app.events
          .where(
            (e) =>
                e.habitId == widget.habitId &&
                e.day == widget.day &&
                !e.deleted,
          )
          .toList();
      final editable =
          valid &&
          !h.archived &&
          app.restOn(h, widget.day) == null &&
          widget.day.compareTo(h.startDay) >= 0 &&
          widget.day.compareTo(app.today) <= 0;
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.eventTitle)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!valid)
                  Text(s.recordChanged)
                else ...[
                  Text(h.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatFullDate(widget.day.date),
                  ),
                  const SizedBox(height: 16),
                  SoftPanel(
                    tinted: true,
                    child: Text(
                      '${quantityText(app.value(h, widget.day) ?? 0)} ${app.planAt(h, widget.day).unit}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (editable)
                    AppAction(
                      key: const Key('event-add'),
                      label: s.eventAdd,
                      icon: Icons.add,
                      primary: true,
                      onTap: app.busy ? null : () => edit(h),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    s.eventClearHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (rows.isEmpty) Text(s.eventEmpty),
                  for (final e in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftPanel(
                        padding: const EdgeInsets.all(4),
                        child: SettingRow(
                          icon: e.kind == RecordEventKind.record
                              ? Icons.receipt_long_outlined
                              : Icons.history_rounded,
                          title:
                              '${e.value < 0 ? '-' : ''}${quantityText(e.value.abs())} ${app.planAt(h, widget.day).unit}',
                          subtitle: [
                            e.kind == RecordEventKind.baseline
                                ? s.eventUnknown
                                : e.kind == RecordEventKind.adjustment
                                ? s.eventAdjustment
                                : e.minute == null
                                ? s.eventNoTime
                                : TimeOfDay(
                                    hour: e.minute! ~/ 60,
                                    minute: e.minute! % 60,
                                  ).format(context),
                            if (e.note.isNotEmpty) e.note,
                          ].join(' · '),
                          onTap: editable && !app.busy
                              ? () => edit(h, e)
                              : null,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class RecordEventEditor extends StatefulWidget {
  const RecordEventEditor({
    super.key,
    required this.app,
    required this.habit,
    required this.day,
    this.event,
  });
  final AppController app;
  final Habit habit;
  final Day day;
  final RecordEvent? event;
  @override
  State<RecordEventEditor> createState() => _RecordEventEditorState();
}

class _RecordEventEditorState extends State<RecordEventEditor> {
  late final int epoch = widget.app.generation;
  late final int revision = widget.app.revision;
  late final String id = widget.event?.id ?? const Uuid().v4();
  late final amount = TextEditingController(
    text: widget.event == null
        ? ''
        : '${widget.event!.value < 0 ? '-' : ''}${quantityText(widget.event!.value.abs())}',
  );
  late final note = TextEditingController(text: widget.event?.note ?? '');
  late int? minute =
      widget.event?.minute ??
      (widget.event == null && widget.day == widget.app.today
          ? widget.app.clock().hour * 60 + widget.app.clock().minute
          : null);
  bool saving = false;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save({bool deleted = false}) async {
    if (saving) return;
    final s = AppLocalizations.of(context);
    final kind = widget.event?.kind ?? RecordEventKind.record;
    final raw = amount.text.trim();
    final negative = raw.startsWith('-');
    final parsed = parseQuantity(negative ? raw.substring(1) : raw);
    if (parsed == null ||
        (negative && kind != RecordEventKind.adjustment) ||
        (!deleted && kind == RecordEventKind.record && parsed == 0) ||
        (widget.habit.kind == HabitKind.count && parsed % 1000 != 0)) {
      setState(() => error = s.invalidQuantity);
      return;
    }
    setState(() => saving = true);
    final event = RecordEvent(
      id: id,
      habitId: widget.habit.id,
      day: widget.day,
      value: negative ? -parsed : parsed,
      minute: kind == RecordEventKind.record ? minute : null,
      note: note.text,
      kind: kind,
      deleted: deleted,
    );
    final ok = widget.event == null
        ? await widget.app.recordIndividual(
            event,
            epoch,
            expectedRevision: revision,
          )
        : await widget.app.run(
            () => widget.app.store.reviseRecordEvent(
              event,
              today: widget.app.today,
              expectedRevision: widget.event!.revision,
            ),
            expectedGeneration: epoch,
          );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        error = s.eventConflict;
      });
    }
  }

  Future<void> remove() async {
    final s = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.eventClearHelp),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (yes == true) await save(deleted: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SheetFrame(
      title: widget.event == null ? s.eventAdd : s.edit,
      subtitle: widget.habit.title,
      icon: Icons.receipt_long_outlined,
      busy: saving,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            MaterialLocalizations.of(context).formatFullDate(widget.day.date),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('event-amount'),
            controller: amount,
            enabled: !saving,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: s.quantityHabit,
              suffixText: widget.app.planAt(widget.habit, widget.day).unit,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.event == null ||
              widget.event!.kind == RecordEventKind.record)
            SettingRow(
              icon: Icons.access_time,
              title: s.eventWhen,
              subtitle: minute == null
                  ? s.eventNoTime
                  : TimeOfDay(
                      hour: minute! ~/ 60,
                      minute: minute! % 60,
                    ).format(context),
              onTap: saving
                  ? null
                  : () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: minute == null
                            ? TimeOfDay.now()
                            : TimeOfDay(
                                hour: minute! ~/ 60,
                                minute: minute! % 60,
                              ),
                      );
                      if (time != null && mounted) {
                        setState(() => minute = time.hour * 60 + time.minute);
                      }
                    },
            ),
          TextField(
            key: const Key('event-note'),
            controller: note,
            enabled: !saving,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(labelText: s.eventNote),
          ),
          if (widget.event != null)
            AppAction(
              label: s.delete,
              icon: Icons.delete_outline,
              onTap: saving ? null : remove,
            ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppAction(
              label: s.cancel,
              onTap: saving ? null : () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppAction(
              key: const Key('event-save'),
              label: s.save,
              primary: true,
              busy: saving,
              onTap: saving ? null : () => save(),
            ),
          ),
        ],
      ),
    );
  }
}
