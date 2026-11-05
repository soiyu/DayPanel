import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

Future<void> openEditor(
  BuildContext context,
  AppController app,
  String type, {
  Habit? habit,
  SmallTask? task,
  Note? note,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      EntryEditor(app: app, type: type, habit: habit, task: task, note: note),
);

class EntryEditor extends StatefulWidget {
  const EntryEditor({
    super.key,
    required this.app,
    required this.type,
    this.habit,
    this.task,
    this.note,
  });
  final AppController app;
  final String type;
  final Habit? habit;
  final SmallTask? task;
  final Note? note;
  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController target;
  late final TextEditingController unit;
  late HabitKind kind;
  late int weekdays, icon;
  Day? due;
  bool saving = false;
  String? error;
  bool get isHabit => widget.type == 'habit';
  bool get isNote => widget.type == 'note';
  @override
  void initState() {
    super.initState();
    title = TextEditingController(
      text:
          widget.habit?.title ?? widget.task?.title ?? widget.note?.body ?? '',
    );
    target = TextEditingController(
      text: quantityText(widget.habit?.target ?? 1000),
    );
    unit = TextEditingController(text: widget.habit?.unit ?? '');
    kind = widget.habit?.kind ?? HabitKind.check;
    weekdays = widget.habit?.weekdays ?? 127;
    icon = widget.habit?.icon ?? 0;
    due = widget.task?.dueDay;
  }

  @override
  void dispose() {
    title.dispose();
    target.dispose();
    unit.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (saving) return;
    final s = AppLocalizations.of(context);
    if (!form.currentState!.validate()) return;
    if (isHabit && weekdays == 0) {
      setState(() => error = s.selectWeekday);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final app = widget.app;
    final ok = await app.run(() async {
      if (isHabit) {
        await app.store.saveHabit(
          Habit(
            id: widget.habit?.id ?? const Uuid().v4(),
            title: title.text.trim(),
            kind: kind,
            startDay: widget.habit?.startDay ?? app.today,
            target: kind == HabitKind.quantity
                ? parseQuantity(target.text)!
                : 1000,
            unit: kind == HabitKind.quantity ? unit.text.trim() : '',
            weekdays: weekdays,
            icon: icon,
            archived: widget.habit?.archived ?? false,
          ),
          create: widget.habit == null,
        );
      } else if (isNote) {
        await app.store.saveNote(
          Note(
            id: widget.note?.id ?? const Uuid().v4(),
            body: title.text.trim(),
            day: widget.note?.day ?? app.today,
          ),
          create: widget.note == null,
        );
      } else {
        await app.store.saveTask(
          SmallTask(
            id: widget.task?.id ?? const Uuid().v4(),
            title: title.text.trim(),
            dueDay: due,
          ),
          create: widget.task == null,
        );
      }
    });
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        error = s.storageError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final names = [
      s.weekMonFull,
      s.weekTueFull,
      s.weekWedFull,
      s.weekThuFull,
      s.weekFriFull,
      s.weekSatFull,
      s.weekSunFull,
    ];
    final heading = isHabit
        ? (widget.habit == null ? s.newHabit : s.editHabit)
        : isNote
        ? (widget.note == null ? s.newNote : s.editNote)
        : (widget.task == null ? s.newTask : s.editTask);
    return PopScope(
      canPop: !saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          heading,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: s.cancel,
                        onPressed: saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('entry-title'),
                    controller: title,
                    enabled: !saving,
                    maxLength: isNote ? 10000 : 100,
                    minLines: isNote ? 5 : 1,
                    maxLines: isNote ? 12 : 2,
                    decoration: InputDecoration(
                      labelText: isNote ? s.noteBody : s.title,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? (isNote ? s.noteRequired : s.invalidTitle)
                        : null,
                  ),
                  if (isHabit) ...[
                    const SizedBox(height: 12),
                    Text(s.type),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final k in HabitKind.values)
                          ChoiceChip(
                            label: Text(
                              k == HabitKind.check
                                  ? s.checkHabit
                                  : s.quantityHabit,
                            ),
                            selected: kind == k,
                            onSelected: saving || widget.habit != null
                                ? null
                                : (_) => setState(() => kind = k),
                          ),
                      ],
                    ),
                    if (kind == HabitKind.quantity) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('habit-target'),
                        controller: target,
                        enabled: !saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(labelText: s.target),
                        validator: (v) => (parseQuantity(v ?? '') ?? 0) <= 0
                            ? s.invalidTarget
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: unit,
                        enabled: !saving,
                        maxLength: 12,
                        decoration: InputDecoration(labelText: s.unit),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(s.schedule),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (var i = 0; i < 7; i++)
                          FilterChip(
                            label: Text(names[i]),
                            selected: (weekdays & (1 << i)) != 0,
                            onSelected: saving
                                ? null
                                : (selected) => setState(() {
                                    weekdays = selected
                                        ? weekdays | (1 << i)
                                        : weekdays & ~(1 << i);
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(s.icon),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: [
                        for (var i = 0; i < habitIcons.length; i++)
                          IconButton.filledTonal(
                            tooltip: '${s.icon} ${i + 1}',
                            isSelected: icon == i,
                            onPressed: saving
                                ? null
                                : () => setState(() => icon = i),
                            icon: Icon(habitIcons[i]),
                          ),
                      ],
                    ),
                  ],
                  if (!isHabit && !isNote) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.dueDate),
                      subtitle: Text(
                        due == null
                            ? s.noDate
                            : MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(due!.date),
                      ),
                      trailing: const Icon(Icons.calendar_month_outlined),
                      onTap: saving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: due?.date ?? widget.app.today.date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null && mounted) {
                                setState(() => due = Day(picked));
                              }
                            },
                    ),
                    if (due != null)
                      TextButton(
                        onPressed: saving
                            ? null
                            : () => setState(() => due = null),
                        child: Text(s.noDate),
                      ),
                  ],
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('save-entry'),
                    onPressed: saving ? null : submit,
                    child: saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(s.save),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openQuantity(
  BuildContext context,
  AppController app,
  Habit habit,
  Day day,
) => showDialog<void>(
  context: context,
  builder: (_) => QuantityEditor(app: app, habit: habit, day: day),
);

class QuantityEditor extends StatefulWidget {
  const QuantityEditor({
    super.key,
    required this.app,
    required this.habit,
    required this.day,
  });
  final AppController app;
  final Habit habit;
  final Day day;
  @override
  State<QuantityEditor> createState() => _QuantityEditorState();
}

class _QuantityEditorState extends State<QuantityEditor> {
  late final TextEditingController value;
  String? error;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final current = widget.app.value(widget.habit, widget.day);
    value = TextEditingController(
      text: current == null ? '' : quantityText(current),
    );
  }

  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  Future<void> save({bool clear = false}) async {
    if (saving) return;
    final s = AppLocalizations.of(context);
    final amount = clear ? null : parseQuantity(value.text);
    if (!clear && amount == null) {
      setState(() => error = s.invalidQuantity);
      return;
    }
    setState(() => saving = true);
    final ok = await widget.app.run(
      () => widget.app.store.setRecord(
        widget.habit.id,
        widget.day,
        amount,
        today: widget.app.today,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        error = s.storageError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return PopScope(
      canPop: !saving,
      child: AlertDialog(
        scrollable: true,
        title: Text(widget.habit.title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MaterialLocalizations.of(context).formatFullDate(widget.day.date),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('quantity-input'),
              controller: value,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: s.total,
                suffixText: widget.habit.unit,
                errorText: error,
              ),
            ),
            const SizedBox(height: 12),
            Text(s.quantityHelp),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => save(clear: true),
            child: Text(s.clearRecord),
          ),
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton(onPressed: saving ? null : save, child: Text(s.save)),
        ],
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, {bool habit = false}) async {
  final s = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.delete),
          content: Text(habit ? s.deleteHabitConfirm : s.deleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.delete),
            ),
          ],
        ),
      ) ??
      false;
}
