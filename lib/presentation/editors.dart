import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../domain/record_event.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'plus_page.dart';
import 'theme.dart';
import 'organization.dart';
import 'appearance.dart';
import 'refined_components.dart';
import 'habit_catalog.dart';
import 'habit_icon.dart';
import 'habits.dart';
import '../domain/habit_templates.dart';

String noteHabitLabel(BuildContext context, AppController app, String? id) {
  final s = AppLocalizations.of(context);
  if (id == null) return s.independentNote;
  final habit = app.habits.where((h) => h.id == id).firstOrNull;
  if (habit == null) return s.noteHabitMissing;
  return '${habit.title}${habit.archived ? ' (${s.archived})' : ''}';
}

class NoteHabitChoice {
  const NoteHabitChoice({this.habitId, this.all = false});
  final String? habitId;
  final bool all;
}

/// null cancels; a choice without a habit explicitly selects independent notes.
Future<NoteHabitChoice?> chooseNoteHabit(
  BuildContext context,
  AppController app, {
  required String? selected,
  bool filter = false,
  bool all = false,
}) {
  final s = AppLocalizations.of(context);
  final choices = <NoteHabitChoice, String>{
    if (filter) const NoteHabitChoice(all: true): s.allNotes,
    const NoteHabitChoice(): s.independentNote,
    for (final h in app.habits)
      NoteHabitChoice(habitId: h.id): noteHabitLabel(context, app, h.id),
  };
  return showModalBottomSheet<NoteHabitChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SheetFrame(
      title: filter ? s.filterNotes : s.noteHabit,
      subtitle: s.noteAssociationHint,
      icon: Icons.link_rounded,
      tone: UiTone.violet,
      body: Column(
        children: [
          for (final choice in choices.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftPanel(
                tinted: selected == choice.key.habitId && all == choice.key.all,
                tone: UiTone.violet,
                padding: EdgeInsets.zero,
                child: SettingRow(
                  icon: choice.key.habitId == null
                      ? Icons.edit_note_rounded
                      : Icons.spa_outlined,
                  title: choice.value,
                  tone: UiTone.violet,
                  trailing: Icon(
                    selected == choice.key.habitId && all == choice.key.all
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: UiTone.violet.ink(ctx),
                  ),
                  onTap: () => Navigator.pop(ctx, choice.key),
                ),
              ),
            ),
        ],
      ),
      footer: AppAction(label: s.cancel, onTap: () => Navigator.pop(ctx)),
    ),
  );
}

Future<void> openEditor(
  BuildContext context,
  AppController app,
  String type, {
  Habit? habit,
  SmallTask? task,
  Note? note,
  String? noteHabitId,
  Day? noteDay,
  int? expectedGeneration,
}) async {
  final epoch = expectedGeneration ?? app.generation;
  HabitTemplate? template;
  var draftTitle = '';
  if (type == 'habit' && habit == null) {
    final choice = await Navigator.push<HabitStarter>(
      context,
      MaterialPageRoute(builder: (_) => const HabitCatalog()),
    );
    if (choice == null || !context.mounted) return;
    template = choice.template;
    draftTitle = choice.title;
  }
  if (!context.mounted) return;
  final createdId = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => EntryEditor(
      app: app,
      type: type,
      habit: habit,
      task: task,
      note: note,
      noteHabitId: noteHabitId,
      noteDay: noteDay,
      expectedGeneration: epoch,
      template: template,
      draftTitle: draftTitle,
      chinese: Localizations.localeOf(context).languageCode == 'zh',
    ),
  );
  if (createdId != null && context.mounted && epoch == app.generation) {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HabitDetails(app: app, id: createdId, initialDay: app.today),
      ),
    );
  }
}

class EntryEditor extends StatefulWidget {
  const EntryEditor({
    super.key,
    required this.app,
    required this.type,
    this.habit,
    this.task,
    this.note,
    this.noteHabitId,
    this.noteDay,
    this.expectedGeneration,
    this.template,
    this.draftTitle = '',
    this.chinese = false,
  });
  final AppController app;
  final String type;
  final Habit? habit;
  final SmallTask? task;
  final Note? note;
  final String? noteHabitId;
  final Day? noteDay;
  final int? expectedGeneration;
  final HabitTemplate? template;
  final String draftTitle;
  final bool chinese;
  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, target, unit;
  late HabitKind kind;
  late int weekdays, icon;
  late String decorationColor, decorationFrame;
  late ScheduleKind schedule;
  bool scheduleChosen = true;
  late HabitContext habitContext;
  String? groupId;
  String? noteHabitId;
  late Day noteDay;
  late final TextEditingController scheduleNumber;
  late int epoch;
  Day? due;
  bool saving = false;
  bool resident = false;
  bool iconManuallyPicked = false;
  String? error;
  bool get isHabit => widget.type == 'habit';
  bool get isNote => widget.type == 'note';
  @override
  void initState() {
    super.initState();
    title = TextEditingController(
      text:
          widget.habit?.title ??
          widget.task?.title ??
          widget.note?.body ??
          widget.template?.title(widget.chinese) ??
          widget.draftTitle,
    );
    target = TextEditingController(
      text: quantityText(
        widget.habit?.target ?? widget.template?.target ?? 1000,
      ),
    );
    unit = TextEditingController(
      text: widget.habit?.unit ?? widget.template?.unit(widget.chinese) ?? '',
    );
    kind = widget.habit?.kind ?? widget.template?.kind ?? HabitKind.check;
    weekdays = widget.habit?.weekdays ?? 127;
    icon = widget.habit?.icon ?? widget.template?.icon ?? 0;
    iconManuallyPicked = widget.habit != null || widget.template != null;
    decorationColor = widget.habit?.color ?? 'auto';
    decorationFrame = widget.habit?.frame ?? 'auto';
    due = widget.task?.dueDay;
    resident = widget.task?.resident ?? false;
    schedule = widget.habit?.schedule ?? ScheduleKind.weekdays;
    scheduleChosen =
        widget.habit != null || !(widget.template?.chooseSchedule ?? false);
    habitContext =
        widget.habit?.context ??
        widget.template?.context ??
        HabitContext.anytime;
    groupId = widget.habit?.groupId;
    scheduleNumber = TextEditingController(
      text:
          '${schedule == ScheduleKind.interval ? (widget.habit?.intervalDays ?? 2) : (widget.habit?.weeklyGoal ?? 3)}',
    );
    epoch = widget.expectedGeneration ?? widget.app.generation;
    noteDay = widget.note?.day ?? widget.noteDay ?? widget.app.today;
    noteHabitId = widget.note?.habitId ?? widget.noteHabitId;
  }

  @override
  void dispose() {
    title.dispose();
    target.dispose();
    unit.dispose();
    scheduleNumber.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (saving) return;
    final s = AppLocalizations.of(context);
    if (!form.currentState!.validate()) return;
    if (isHabit &&
        icon >= 24 &&
        icon != widget.habit?.icon &&
        !await requirePlus(context, widget.app)) {
      return;
    }
    if (!mounted) return;
    if (isHabit &&
        kind == HabitKind.check &&
        schedule == ScheduleKind.weeklyTotal) {
      setState(() => error = s.weeklyTotalHint);
      return;
    }
    if (isHabit && !scheduleChosen) {
      setState(() => error = s.chooseScheduleHelp);
      return;
    }
    if (isHabit && schedule == ScheduleKind.weekdays && weekdays == 0) {
      setState(() => error = s.selectWeekday);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final app = widget.app;
    final createdId = isHabit && widget.habit == null
        ? const Uuid().v4()
        : null;
    final ok = await app.run(() async {
      if (isHabit) {
        await app.store.saveHabit(
          Habit(
            id: widget.habit?.id ?? createdId!,
            title: title.text.trim(),
            kind: kind,
            startDay: widget.habit?.startDay ?? app.today,
            target: kind.isNumeric ? parseQuantity(target.text)! : 1000,
            unit: kind.isNumeric ? unit.text.trim() : '',
            weekdays: weekdays == 0 ? 127 : weekdays,
            icon: icon,
            color: decorationColor,
            frame: decorationFrame,
            archived: widget.habit?.archived ?? false,
            context: habitContext,
            groupId: groupId,
            position: widget.habit?.position ?? 0,
            schedule: schedule,
            intervalDays: schedule == ScheduleKind.interval
                ? int.parse(scheduleNumber.text)
                : widget.habit?.intervalDays ?? 1,
            weeklyGoal: schedule == ScheduleKind.weekly
                ? int.parse(scheduleNumber.text)
                : widget.habit?.weeklyGoal ?? 3,
          ),
          create: widget.habit == null,
          today: app.today,
        );
      } else if (isNote) {
        await app.store.saveNote(
          Note(
            id: widget.note?.id ?? const Uuid().v4(),
            body: title.text.trim(),
            day: noteDay,
            habitId: noteHabitId,
          ),
          create: widget.note == null,
          today: app.today,
        );
      } else {
        await app.store.saveTask(
          SmallTask(
            id: widget.task?.id ?? const Uuid().v4(),
            title: title.text.trim(),
            dueDay: resident ? null : due,
            resident: resident,
            startDay: resident ? (widget.task?.startDay ?? app.today) : null,
            archived: widget.task?.archived ?? false,
          ),
          create: widget.task == null,
          today: app.today,
        );
      }
    }, expectedGeneration: epoch);
    if (!mounted) return;
    if (ok) {
      if (isNote) {
        app.revealNoteDay(noteDay);
      }
      Navigator.pop(context, createdId);
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
      icon: isHabit
          ? habitIcons[icon]
          : isNote
          ? Icons.edit_note_rounded
          : Icons.checklist_rounded,
      tone: tone,
      leading: isHabit
          ? HabitIcon(icon, color: decorationColor, frame: decorationFrame)
          : null,
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
              onChanged: isHabit
                  ? (value) => setState(() {
                      if (widget.habit == null && !iconManuallyPicked) {
                        icon =
                            suggestedHabitIcon(value) ??
                            widget.template?.icon ??
                            0;
                      }
                    })
                  : null,
              enabled: !saving,
              maxLength: isNote ? 10000 : 100,
              minLines: isNote ? 4 : 1,
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
            if (isNote) ...[
              const SizedBox(height: 16),
              fieldLabel(s.noteDate),
              SoftPanel(
                tone: UiTone.peach,
                tinted: true,
                padding: EdgeInsets.zero,
                child: SettingRow(
                  key: const Key('note-date'),
                  icon: Icons.calendar_today_outlined,
                  title: DateFormat.yMMMd(
                    Localizations.localeOf(context).languageCode,
                  ).format(noteDay.date),
                  tone: UiTone.peach,
                  onTap: saving
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          final value = await showDatePicker(
                            context: context,
                            initialDate:
                                noteDay.date.isAfter(widget.app.today.date)
                                ? widget.app.today.date
                                : noteDay.date,
                            firstDate: DateTime(1900),
                            lastDate: widget.app.today.date,
                          );
                          if (value != null && mounted) {
                            setState(() => noteDay = Day(value));
                          }
                        },
                ),
              ),
              const SizedBox(height: 16),
              fieldLabel(s.noteHabit),
              SoftPanel(
                tone: UiTone.violet,
                tinted: true,
                padding: EdgeInsets.zero,
                child: SettingRow(
                  key: const Key('note-habit'),
                  icon: Icons.link_rounded,
                  title: noteHabitLabel(context, widget.app, noteHabitId),
                  tone: UiTone.violet,
                  onTap: saving
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          final choice = await chooseNoteHabit(
                            context,
                            widget.app,
                            selected: noteHabitId,
                          );
                          if (choice != null && mounted) {
                            setState(() => noteHabitId = choice.habitId);
                          }
                        },
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (isHabit) ...[
              if (widget.template != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    s.templateEditable,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (suggestedHabitIcon(title.text) case final int suggestion
                  when suggestion != icon)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SettingRow(
                    key: const Key('apply-suggested-icon'),
                    leading: HabitIcon(suggestion, size: 42),
                    icon: habitIcons[suggestion],
                    title: s.suggestedIcon(iconLabels(s)[suggestion]),
                    subtitle: s.iconSuggestionHint,
                    onTap: saving
                        ? null
                        : () => setState(() {
                            icon = suggestion;
                            iconManuallyPicked = true;
                          }),
                  ),
                ),
              const SizedBox(height: 22),
              if (widget.habit == null) ...[
                fieldLabel(s.type),
                ResponsiveChoices(
                  minWidth: 120,
                  maxColumns: 3,
                  children: [
                    for (final k in HabitKind.values)
                      QuietChoice(
                        key: Key('habit-kind-${k.name}'),
                        label: switch (k) {
                          HabitKind.check => s.checkHabit,
                          HabitKind.quantity => s.quantityHabit,
                          HabitKind.count => s.countHabit,
                        },
                        icon: switch (k) {
                          HabitKind.check => Icons.task_alt_rounded,
                          HabitKind.quantity => Icons.straighten_rounded,
                          HabitKind.count => Icons.pin_outlined,
                        },
                        selected: kind == k,
                        onTap: saving
                            ? null
                            : () => setState(() {
                                if (kind == k) return;
                                if (k == HabitKind.count) {
                                  target.text = '1';
                                  unit.text = s.countUnit;
                                } else if (kind == HabitKind.count &&
                                    k == HabitKind.quantity) {
                                  unit.clear();
                                }
                                kind = k;
                              }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(switch (kind) {
                  HabitKind.check => s.recordingCheckHelp,
                  HabitKind.quantity => s.recordingQuantityHelp,
                  HabitKind.count => s.recordingCountHelp,
                }, style: Theme.of(context).textTheme.bodySmall),
              ] else
                Padding(
                  key: const Key('habit-type-readonly'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.type}: ${switch (kind) {
                          HabitKind.check => s.checkHabit,
                          HabitKind.quantity => s.quantityHabit,
                          HabitKind.count => s.countHabit,
                        }}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.habitTypeFixed,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              if (widget.habit != null && kind.isNumeric)
                Padding(
                  key: const Key('plan-tomorrow-target'),
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.planTomorrow,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (kind.isNumeric) ...[
                const SizedBox(height: 20),
                fieldLabel(
                  schedule == ScheduleKind.weeklyTotal
                      ? s.weeklyTargetAmount
                      : s.target,
                ),
                TextFormField(
                  key: const Key('habit-target'),
                  controller: target,
                  enabled: !saving,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: kind != HabitKind.count,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: schedule == ScheduleKind.weeklyTotal
                        ? s.weeklyTargetAmount
                        : s.target,
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                  validator: (v) {
                    final n = parseQuantity(v ?? '');
                    if (kind == HabitKind.count &&
                        (n == null || n <= 0 || n % 1000 != 0)) {
                      return s.countTargetError;
                    }
                    return n == null || n <= 0 ? s.invalidTarget : null;
                  },
                ),
                const SizedBox(height: 14),
                fieldLabel(s.unit),
                TextFormField(
                  key: const Key('habit-unit'),
                  controller: unit,
                  onChanged: (_) => setState(() {}),
                  enabled: !saving,
                  maxLength: 12,
                  decoration: InputDecoration(
                    hintText: s.unitPlaceholder,
                    counterText: '',
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (widget.habit != null)
                Padding(
                  key: const Key('plan-tomorrow-frequency'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    s.planTomorrow,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              fieldLabel(s.frequency),
              if (!scheduleChosen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(s.chooseScheduleHelp),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in ScheduleKind.values.where(
                    (v) => kind.isNumeric || v != ScheduleKind.weeklyTotal,
                  ))
                    AppAction(
                      label: switch (mode) {
                        ScheduleKind.weekdays => s.byWeekday,
                        ScheduleKind.interval => s.everyNDays,
                        ScheduleKind.weekly => s.weeklyTarget,
                        ScheduleKind.weeklyTotal =>
                          '${s.weeklyTotalLabel} · PLUS',
                      },
                      key: Key('habit-schedule-${mode.name}'),
                      icon: scheduleChosen && schedule == mode
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      tone: UiTone.violet,
                      onTap: saving
                          ? null
                          : () async {
                              if (mode == ScheduleKind.weeklyTotal &&
                                  !await requirePlus(context, widget.app)) {
                                return;
                              }
                              if (!mounted) return;
                              setState(() {
                                scheduleChosen = true;
                                error = null;
                                if (schedule == mode) return;
                                schedule = mode;
                                scheduleNumber.text =
                                    mode == ScheduleKind.interval ? '2' : '3';
                              });
                            },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (schedule == ScheduleKind.interval ||
                  schedule == ScheduleKind.weekly) ...[
                TextFormField(
                  key: const Key('schedule-number'),
                  controller: scheduleNumber,
                  onChanged: (_) => setState(() {}),
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: schedule == ScheduleKind.interval
                        ? s.intervalLabel
                        : s.weeklyGoalLabel,
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null ||
                            n < 1 ||
                            n > (schedule == ScheduleKind.interval ? 365 : 7)
                        ? s.scheduleNumberError
                        : null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  schedule == ScheduleKind.weekly
                      ? s.weeklyHint
                      : s.scheduleStarts,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (schedule == ScheduleKind.weeklyTotal)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(s.weeklyTotalHint),
                ),
              if (schedule == ScheduleKind.weekdays)
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
                                          scheduleChosen = true;
                                          error = null;
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
                                          : Theme.of(
                                              context,
                                            ).colorScheme.surface,
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
              const SizedBox(height: 14),
              SoftPanel(
                key: const Key('habit-rule-preview'),
                padding: const EdgeInsets.all(12),
                tinted: true,
                tone: UiTone.violet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.recordingRuleTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      !scheduleChosen
                          ? s.chooseSchedule
                          : scheduleText(
                              s,
                              HabitPlan(
                                habitId: widget.habit?.id ?? 'draft',
                                effectiveDay: widget.habit == null
                                    ? widget.app.today
                                    : widget.app.today.plus(1),
                                target: parseQuantity(target.text) ?? 1000,
                                unit: unit.text.trim(),
                                weekdays: weekdays,
                                schedule: schedule,
                                intervalDays:
                                    int.tryParse(scheduleNumber.text) ?? 1,
                                weeklyGoal:
                                    int.tryParse(scheduleNumber.text) ?? 1,
                              ),
                            ),
                    ),
                    Text(
                      kind == HabitKind.check
                          ? s.recordingCheckHelp
                          : '${schedule == ScheduleKind.weeklyTotal ? s.weeklyTargetAmount : s.target}: ${target.text} ${unit.text.trim()}',
                    ),
                    if (scheduleChosen && schedule == ScheduleKind.weekly)
                      Text(
                        s.weeklyCountingHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                child: DetailDisclosure(
                  key: const Key('habit-advanced-settings'),
                  title: s.habitAdvancedSettings,
                  icon: Icons.tune_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 22),
                      fieldLabel(s.contextLabel),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in HabitContext.values)
                            AppAction(
                              label: contextName(s, c),
                              icon: habitContext == c
                                  ? Icons.check_circle_rounded
                                  : contextIcon(c),
                              tone: UiTone.peach,
                              onTap: saving
                                  ? null
                                  : () => setState(() => habitContext = c),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      fieldLabel(s.groupLabel),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final g in <HabitGroup?>[
                            null,
                            ...widget.app.groups,
                          ])
                            AppAction(
                              label: g?.name ?? s.ungrouped,
                              icon: groupId == g?.id
                                  ? Icons.check_circle_rounded
                                  : Icons.folder_outlined,
                              tone: UiTone.violet,
                              onTap: saving
                                  ? null
                                  : () => setState(() => groupId = g?.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      HabitStylePicker(
                        icon: icon,
                        color: decorationColor,
                        frame: decorationFrame,
                        title: title.text,
                        onIcon: saving
                            ? null
                            : (v) => setState(() {
                                icon = v;
                                iconManuallyPicked = true;
                              }),
                        onColor: saving
                            ? null
                            : (v) => setState(() => decorationColor = v),
                        onFrame: saving
                            ? null
                            : (v) => setState(() => decorationFrame = v),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!isHabit && !isNote) ...[
              const SizedBox(height: 20),
              if (widget.task == null) ...[
                fieldLabel(s.taskKind),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final keep in [false, true])
                        SizedBox(
                          width: (constraints.maxWidth - 10) / 2,
                          child: _TypeChoice(
                            label: keep ? s.residentTask : s.oneTimeTask,
                            icon: keep
                                ? Icons.bookmark_border_rounded
                                : Icons.check_circle_outline_rounded,
                            selected: resident == keep,
                            enabled: !saving && widget.task == null,
                            onTap: () => setState(() => resident = keep),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else
                Padding(
                  key: const Key('task-type-readonly'),
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${s.taskKind}: ${resident ? s.residentTask : s.oneTimeTask}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                resident ? s.residentHelp : s.oneTimeHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (widget.task != null) ...[
                const SizedBox(height: 8),
                Text(
                  s.taskTypeFixed,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
            if (!isHabit && !isNote && !resident) ...[
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
              onTap: saving
                  ? null
                  : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(context);
                    },
              tone: tone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex:
                MediaQuery.sizeOf(context).width < 360 &&
                    MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 1
                : 2,
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
    this.onSave,
    this.onSaveEvent,
  });
  final AppController app;
  final Habit habit;
  final Day day;
  final Future<bool> Function(int? value, int expectedRevision)? onSave;
  final Future<bool> Function(RecordEvent event, int expectedRevision)?
  onSaveEvent;
  @override
  State<QuantityEditor> createState() => _QuantityEditorState();
}

class _QuantityEditorState extends State<QuantityEditor> {
  late final TextEditingController value;
  late final int epoch;
  late int revision;
  late Habit snapshot;
  int? previous;
  String? error;
  bool saving = false;
  final eventId = const Uuid().v4();
  bool adding = false;
  bool stale = false;

  @override
  void initState() {
    super.initState();
    epoch = widget.app.generation;
    revision = widget.app.revision;
    snapshot = widget.app.forDay(widget.habit, widget.day);
    previous = widget.app.value(widget.habit, widget.day);
    value = TextEditingController(
      text: previous == null ? '' : quantityText(previous!),
    );
  }

  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  int? get inputAmount {
    final parsed = parseQuantity(value.text);
    if (parsed == null ||
        (snapshot.kind == HabitKind.count && parsed % 1000 != 0)) {
      return null;
    }
    return parsed;
  }

  int? get result {
    final amount = inputAmount;
    if (amount == null || (adding && amount == 0)) return null;
    final total = adding ? (previous ?? 0) + amount : amount;
    return total > 999999999999 ? null : total;
  }

  Future<void> reload() async {
    if (saving || widget.app.generation != epoch) return;
    setState(() => saving = true);
    try {
      await widget.app.load();
      if (!mounted) return;
      final h = widget.app.habits
          .where((h) => h.id == widget.habit.id)
          .firstOrNull;
      if (widget.app.generation != epoch || h == null || !h.kind.isNumeric) {
        setState(() {
          saving = false;
          stale = true;
          error = AppLocalizations.of(context).recordChanged;
        });
        return;
      }
      setState(() {
        snapshot = widget.app.forDay(h, widget.day);
        previous = widget.app.value(h, widget.day);
        revision = widget.app.revision;
        value.text = previous == null ? '' : quantityText(previous!);
        adding = false;
        stale = false;
        saving = false;
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = AppLocalizations.of(context).storageError;
        });
      }
    }
  }

  Future<void> save({bool clear = false}) async {
    if (saving || stale) return;
    final s = AppLocalizations.of(context);
    final amount = clear ? null : result;
    if (!clear && amount == null) {
      setState(
        () => error = snapshot.kind == HabitKind.count
            ? s.countWholeError
            : s.invalidQuantity,
      );
      return;
    }
    if (epoch != widget.app.generation || revision != widget.app.revision) {
      setState(() {
        stale = true;
        error = s.recordChanged;
      });
      return;
    }
    setState(() => saving = true);
    final now = widget.app.clock();
    final event = RecordEvent(
      id: eventId,
      habitId: snapshot.id,
      day: widget.day,
      value: inputAmount ?? 0,
      minute: widget.day == widget.app.today
          ? now.hour * 60 + now.minute
          : null,
    );
    final logEvent =
        !clear &&
        adding &&
        widget.app.plus.enabled &&
        (widget.onSave == null || widget.onSaveEvent != null);
    final ok = logEvent
        ? (widget.onSaveEvent != null
              ? await widget.onSaveEvent!(event, revision)
              : await widget.app.recordIndividual(
                  event,
                  epoch,
                  expectedRevision: revision,
                ))
        : widget.onSave != null
        ? await widget.onSave!(amount, revision)
        : await widget.app.recordHabit(
            snapshot,
            widget.day,
            amount,
            epoch,
            expectedRevision: revision,
          );
    if (!mounted) return;
    if (ok) {
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        stale =
            widget.app.generation != epoch ||
            widget.app.revision != revision ||
            widget.app.error == 'record_conflict';
        error = stale ? s.recordChanged : s.storageError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final h = snapshot;
    final count = h.kind == HabitKind.count;
    final tone = habitTone(h.icon, h.color);
    return SheetFrame(
      title: h.title,
      subtitle: MaterialLocalizations.of(
        context,
      ).formatFullDate(widget.day.date),
      icon: habitIcons[h.icon],
      leading: HabitIcon(h.icon, color: h.color, frame: h.frame),
      tone: tone,
      busy: saving,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveChoices(
            minWidth: 140,
            maxColumns: 2,
            children: [
              for (final add in [false, true])
                AppAction(
                  key: Key(add ? 'quantity-mode-add' : 'quantity-mode-total'),
                  label: add
                      ? (count ? s.countAddMode : s.quantityAddMode)
                      : (count ? s.countSetMode : s.quantitySetMode),
                  icon: adding == add
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  tone: tone,
                  onTap: saving || stale
                      ? null
                      : () => setState(() {
                          if (adding == add) return;
                          adding = add;
                          value.text = add
                              ? (count ? '1' : '')
                              : (previous == null
                                    ? ''
                                    : quantityText(previous!));
                          error = null;
                        }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            adding
                ? (count ? s.countAddMode : s.quantityAddMode)
                : (count ? s.countSetMode : s.quantityReplaceTotal),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('quantity-input'),
            controller: value,
            enabled: !saving && !stale,
            keyboardType: TextInputType.numberWithOptions(decimal: !count),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: h.unit,
              errorText: error,
              errorMaxLines: 3,
            ),
            onChanged: (_) => setState(() => error = null),
          ),
          const SizedBox(height: 8),
          Wrap(
            key: const Key('quantity-saved-summary'),
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                s.quantitySavedTotal(
                  previous == null ? '—' : quantityText(previous!),
                  h.unit,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${h.schedule == ScheduleKind.weeklyTotal ? s.weeklyTargetAmount : s.target}: ${quantityText(h.target)} ${h.unit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              result == null
                  ? (adding ? s.quantityAddHint : s.quantityTotalHint)
                  : adding
                  ? s.quantityAddPreview(
                      quantityText(previous ?? 0),
                      h.unit,
                      quantityText(inputAmount!),
                      quantityText(result!),
                    )
                  : s.quantityReplacePreview(quantityText(result!), h.unit),
              key: const Key('quantity-replace-preview'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (stale && widget.app.generation == epoch) ...[
            const SizedBox(height: 10),
            AppAction(
              key: const Key('quantity-reload'),
              label: s.reloadRecord,
              icon: Icons.refresh_rounded,
              onTap: saving ? null : reload,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            adding
                ? (count ? s.countAddMode : s.quantityAddMode)
                : s.prefillTotal,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final total
                    in (adding
                        ? quantityIncrementSuggestions(
                            h.target,
                            h.unit,
                            wholeCounts: count,
                          )
                        : quantitySuggestions(
                            h.target,
                            h.unit,
                            wholeCounts: count,
                          )))
                  SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: AppAction(
                      label: adding
                          ? '+${quantityText(total)} ${h.unit}'
                          : '${quantityText(total)} ${h.unit}',
                      tone: tone,
                      onTap: saving || stale
                          ? null
                          : () => setState(() {
                              value.text = quantityText(total);
                              error = null;
                            }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (previous != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('quantity-clear'),
                onPressed: saving || stale ? null : () => save(clear: true),
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
              onTap: saving
                  ? null
                  : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(context);
                    },
              tone: tone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex:
                MediaQuery.sizeOf(context).width < 360 &&
                    MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 1
                : 2,
            child: AppAction(
              key: const Key('quantity-save'),
              label: s.save,
              icon: Icons.check_rounded,
              primary: true,
              busy: saving,
              onTap: saving || stale ? null : save,
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
