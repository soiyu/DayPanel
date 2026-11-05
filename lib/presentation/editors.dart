import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
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
  late final TextEditingController title, target, unit;
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

  Widget fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
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
    final short = [
      s.weekMon,
      s.weekTue,
      s.weekWed,
      s.weekThu,
      s.weekFri,
      s.weekSat,
      s.weekSun,
    ];
    final heading = isHabit
        ? (widget.habit == null ? s.newHabit : s.editHabit)
        : isNote
        ? (widget.note == null ? s.newNote : s.editNote)
        : (widget.task == null ? s.newTask : s.editTask);
    final tone = isNote
        ? UiTone.violet
        : isHabit
        ? UiTone.blue
        : UiTone.peach;
    return SheetFrame(
      title: heading,
      subtitle: isHabit
          ? s.habitEditorHint
          : isNote
          ? s.journalEmptyHint
          : s.taskEditorHint,
      icon: isHabit
          ? habitIcons[icon]
          : isNote
          ? Icons.edit_note_rounded
          : Icons.checklist_rounded,
      tone: tone,
      busy: saving,
      body: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fieldLabel(isNote ? s.noteBody : s.title),
            TextFormField(
              key: const Key('entry-title'),
              controller: title,
              enabled: !saving,
              maxLength: isNote ? 10000 : 100,
              minLines: isNote ? 5 : 1,
              maxLines: isNote ? 12 : 2,
              decoration: InputDecoration(
                hintText: isNote
                    ? s.notePlaceholder
                    : isHabit
                    ? s.habitPlaceholder
                    : s.taskPlaceholder,
                counterText: '',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? (isNote ? s.noteRequired : s.invalidTitle)
                  : null,
            ),
            if (isHabit) ...[
              const SizedBox(height: 22),
              fieldLabel(s.type),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final k in HabitKind.values)
                      SizedBox(
                        width: (constraints.maxWidth - 10) / 2,
                        child: _TypeChoice(
                          label: k == HabitKind.check
                              ? s.checkHabit
                              : s.quantityHabit,
                          icon: k == HabitKind.check
                              ? Icons.task_alt_rounded
                              : Icons.water_drop_outlined,
                          selected: kind == k,
                          enabled: !saving && widget.habit == null,
                          onTap: () => setState(() => kind = k),
                        ),
                      ),
                  ],
                ),
              ),
              if (kind == HabitKind.quantity) ...[
                const SizedBox(height: 20),
                fieldLabel(s.target),
                TextFormField(
                  key: const Key('habit-target'),
                  controller: target,
                  enabled: !saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: s.target,
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                  validator: (v) => (parseQuantity(v ?? '') ?? 0) <= 0
                      ? s.invalidTarget
                      : null,
                ),
                const SizedBox(height: 14),
                fieldLabel(s.unit),
                TextFormField(
                  controller: unit,
                  enabled: !saving,
                  maxLength: 12,
                  decoration: InputDecoration(
                    hintText: s.unitPlaceholder,
                    counterText: '',
                  ),
                ),
              ],
              const SizedBox(height: 22),
              fieldLabel(s.schedule),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Padding(
                        padding: EdgeInsets.only(right: i == 6 ? 0 : 4),
                        child: Tooltip(
                          message: names[i],
                          child: Semantics(
                            label: names[i],
                            selected: (weekdays & (1 << i)) != 0,
                            button: true,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: saving
                                    ? null
                                    : () => setState(() {
                                        weekdays = (weekdays & (1 << i)) == 0
                                            ? weekdays | (1 << i)
                                            : weekdays & ~(1 << i);
                                      }),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 52,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: (weekdays & (1 << i)) != 0
                                        ? UiTone.blue.wash(context)
                                        : Theme.of(context).colorScheme.surface,
                                    border: Border.all(
                                      color: (weekdays & (1 << i)) != 0
                                          ? UiTone.blue
                                                .ink(context)
                                                .withValues(alpha: .4)
                                          : Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Text(
                                    short[i],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: (weekdays & (1 << i)) != 0
                                          ? UiTone.blue.ink(context)
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              fieldLabel(s.icon),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < habitIcons.length; i++)
                    Semantics(
                      selected: icon == i,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            width: 1.5,
                            color: icon == i
                                ? habitTone(i).ink(context)
                                : Colors.transparent,
                          ),
                        ),
                        child: AppIconAction(
                          icon: habitIcons[i],
                          label: '${s.icon} ${i + 1}',
                          tone: habitTone(i),
                          onTap: saving ? null : () => setState(() => icon = i),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (!isHabit && !isNote) ...[
              const SizedBox(height: 20),
              fieldLabel(s.dueDate),
              SoftPanel(
                tinted: true,
                tone: UiTone.peach,
                padding: EdgeInsets.zero,
                child: SettingRow(
                  icon: Icons.calendar_month_outlined,
                  tone: UiTone.peach,
                  title: due == null
                      ? s.noDate
                      : MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(due!.date),
                  subtitle: s.chooseDate,
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
              ),
              if (due != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: saving ? null : () => setState(() => due = null),
                    child: Text(s.noDate),
                  ),
                ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppAction(
              label: s.cancel,
              onTap: saving ? null : () => Navigator.pop(context),
              tone: tone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppAction(
              key: const Key('save-entry'),
              label: s.save,
              icon: Icons.check_rounded,
              primary: true,
              busy: saving,
              onTap: saving ? null : submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChoice extends StatelessWidget {
  const _TypeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected, enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    enabled: enabled,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? UiTone.blue.wash(context)
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: selected
                  ? UiTone.blue.ink(context).withValues(alpha: .5)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? UiTone.blue.ink(context)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: selected
                        ? UiTone.blue.ink(context)
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> openQuantity(
  BuildContext context,
  AppController app,
  Habit habit,
  Day day,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
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
    final h = widget.habit;
    final current = widget.app.value(h, widget.day);
    final tone = habitTone(h.icon);
    return SheetFrame(
      title: h.title,
      subtitle: MaterialLocalizations.of(
        context,
      ).formatFullDate(widget.day.date),
      icon: habitIcons[h.icon],
      tone: tone,
      busy: saving,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftPanel(
            tinted: true,
            tone: tone,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.currentRecord,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      current == null ? '—' : quantityText(current),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontSize: 34, color: tone.ink(context)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        h.unit,
                        style: TextStyle(
                          color: tone.ink(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ((current ?? 0) / h.target).clamp(0.0, 1.0),
                    minHeight: 5,
                    color: tone.ink(context),
                    backgroundColor: tone.wash(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.target}  ${quantityText(h.target)} ${h.unit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(s.total, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 9),
          TextField(
            key: const Key('quantity-input'),
            controller: value,
            enabled: !saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: h.unit,
              errorText: error,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.confirmBeforeWrite,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text(s.prefillTotal, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final fraction in [.25, .5, .75, 1.0])
                  SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: AppAction(
                      label:
                          '${quantityText((h.target * fraction).round())} ${h.unit}',
                      tone: tone,
                      onTap: saving
                          ? null
                          : () => setState(() {
                              value.text = quantityText(
                                (h.target * fraction).round(),
                              );
                              error = null;
                            }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(s.quantityHelp, style: Theme.of(context).textTheme.bodySmall),
          if (current != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: saving ? null : () => save(clear: true),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(s.clearRecord),
              ),
            ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppAction(
              label: s.cancel,
              onTap: saving ? null : () => Navigator.pop(context),
              tone: tone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppAction(
              label: s.save,
              icon: Icons.check_rounded,
              primary: true,
              busy: saving,
              onTap: saving ? null : save,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, {bool habit = false}) async {
  final s = AppLocalizations.of(context);
  return await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (ctx) => SheetFrame(
          title: s.delete,
          icon: Icons.delete_outline_rounded,
          tone: UiTone.peach,
          body: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              habit ? s.deleteHabitConfirm : s.deleteConfirm,
              style: Theme.of(ctx).textTheme.bodyLarge,
            ),
          ),
          footer: Row(
            children: [
              Expanded(
                child: AppAction(
                  label: s.cancel,
                  onTap: () => Navigator.pop(ctx, false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppAction(
                  label: s.delete,
                  icon: Icons.delete_outline_rounded,
                  danger: true,
                  onTap: () => Navigator.pop(ctx, true),
                ),
              ),
            ],
          ),
        ),
      ) ??
      false;
}
