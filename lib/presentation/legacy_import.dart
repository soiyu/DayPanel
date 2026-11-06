import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../data/app_store.dart';
import '../data/legacy_files.dart';
import '../domain/legacy_import.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'refined_components.dart';

class LegacyImportPage extends StatefulWidget {
  const LegacyImportPage({super.key, required this.app, this.files});
  final AppController app;
  final LegacyFiles? files;
  @override
  State<LegacyImportPage> createState() => _LegacyImportPageState();
}

class _LegacyImportPageState extends State<LegacyImportPage> {
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  LegacyImport? source;
  int epoch = 0;
  int stage = 0;
  Set<String> existing = {}, selected = {};
  final schedules = <String, LegacySchedule>{};
  bool working = false, acknowledged = false;
  String? message;
  Future<void> pick() async {
    if (working) return;
    setState(() {
      working = true;
      message = null;
    });
    try {
      final pickedEpoch = widget.app.generation;
      final raw = await (widget.files ?? AndroidLegacyFiles()).pick();
      if (raw == null || !mounted) return;
      final preview = LegacyImport.decode(raw, today: widget.app.today);
      await widget.app.load();
      if (pickedEpoch != widget.app.generation) throw const LegacyInvalid();
      existing = widget.app.habits.map((h) => h.id).toSet();
      selected = {
        for (final h in preview.habits)
          if (h.unsupported == null && !existing.contains(h.id)) h.id,
      };
      schedules.clear();
      for (final h in preview.habits.where((h) => h.daily)) {
        schedules[h.id] = const LegacySchedule(ScheduleKind.weekdays);
      }
      if (mounted) {
        setState(() {
          epoch = pickedEpoch;
          source = preview;
          stage = 1;
          acknowledged = false;
        });
        if (scroll.hasClients) scroll.jumpTo(0);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          source = null;
          stage = 0;
          message = AppLocalizations.of(context).legacyInvalid;
        });
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> schedule(LegacyHabit h) async {
    final choice = await showModalBottomSheet<LegacySchedule>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ScheduleEditor(initial: schedules[h.id]),
    );
    if (choice != null && mounted) {
      setState(() {
        schedules[h.id] = choice;
        acknowledged = false;
      });
    }
  }

  Future<void> commit() async {
    if (working || source == null) return;
    final s = AppLocalizations.of(context);
    setState(() => working = true);
    var committed = false;
    final ok = await widget.app.run(() async {
      await widget.app.store.importLegacy(
        source!,
        {for (final id in selected) id: schedules[id]!},
        today: widget.app.today,
        chinese: s.localeName.startsWith('zh'),
      );
      committed = true;
    }, expectedGeneration: epoch);
    if (!mounted) return;
    setState(() {
      working = false;
      message = ok
          ? s.legacyDone
          : committed
          ? s.restoreRefreshFailed
          : s.legacyFailed;
      if (ok || committed) {
        source = null;
        stage = 3;
      }
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  String label(AppLocalizations s, LegacySchedule? choice) => choice == null
      ? s.legacyChooseSchedule
      : switch (choice.kind) {
          ScheduleKind.weekdays => s.legacyDaily,
          ScheduleKind.weekly => '${s.legacyWeekly} · ${choice.count}',
          ScheduleKind.interval => '${s.legacyInterval} · ${choice.count}',
        };
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final canReview =
        !working &&
        selected.isNotEmpty &&
        selected.every(schedules.containsKey);
    final selectedHabits =
        source?.habits.where((h) => selected.contains(h.id)).toList() ?? [];
    final scheme = Theme.of(context).colorScheme;
    final help = selected.isEmpty
        ? s.uiImportNoSelection
        : !selected.every(schedules.containsKey)
        ? s.uiImportNeedsSchedule
        : s.uiSelectedCount(selected.length);
    return PopScope(
      canPop: !working && stage != 2,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !working && stage == 2) setState(() => stage = 1);
      },
      child: AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.legacyTitle),
            automaticallyImplyLeading: !working,
            actions: [
              if (source != null)
                IconButton(
                  key: const Key('legacy-change-file'),
                  tooltip: s.uiChangeFile,
                  icon: const Icon(Icons.folder_open_outlined),
                  onPressed: working ? null : pick,
                ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      if (stage < 3)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Row(
                            children: [
                              for (var i = 0; i < 3; i++) ...[
                                if (i > 0)
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      color: i <= stage
                                          ? scheme.primary
                                          : scheme.outlineVariant,
                                    ),
                                  ),
                                Semantics(
                                  label: [
                                    s.uiChooseFile,
                                    s.uiChooseItems,
                                    s.uiReviewImport,
                                  ][i],
                                  selected: stage == i,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: i <= stage
                                          ? scheme.primaryContainer
                                          : scheme.surfaceContainerHighest,
                                      shape: BoxShape.circle,
                                    ),
                                    child: i < stage
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: scheme.primary,
                                          )
                                        : Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              color: i == stage
                                                  ? scheme.primary
                                                  : scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (stage == 0) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: ToneIcon(
                              Icons.drive_file_move_outline,
                              tone: UiTone.violet,
                              size: 72,
                            ),
                          ),
                        ),
                        Text(
                          s.uiChooseFile,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.legacyIntro,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        AppAction(
                          key: const Key('legacy-pick'),
                          label: s.legacyPick,
                          icon: Icons.folder_open,
                          primary: true,
                          busy: working,
                          onTap: working ? null : pick,
                        ),
                        const SizedBox(height: 16),
                        DetailDisclosure(
                          title: s.uiFileScope,
                          child: Text(s.legacySupported),
                        ),
                      ],
                      if (message != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: SoftPanel(
                            tinted: true,
                            tone: stage == 3 ? UiTone.blue : UiTone.peach,
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  stage == 3
                                      ? Icons.check_circle_outline
                                      : Icons.info_outline_rounded,
                                  color: stage == 3
                                      ? scheme.primary
                                      : UiTone.peach.ink(context),
                                  size: 30,
                                ),
                                const SizedBox(height: 12),
                                if (stage == 3) ...[
                                  Text(
                                    s.uiImportedDone,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(message!),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (stage == 3) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          key: const Key('legacy-pick'),
                          onPressed: working ? null : pick,
                          icon: const Icon(Icons.folder_open),
                          label: Text(s.uiChangeFile),
                        ),
                      ],
                      if (source != null && stage == 1) ...[
                        Text(
                          s.uiChooseItems,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.uiImportSelectHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 18),
                        for (final h in source!.habits) _item(context, h),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          key: const Key('legacy-pick'),
                          onPressed: working ? null : pick,
                          icon: const Icon(Icons.folder_open),
                          label: Text(s.uiChangeFile),
                        ),
                      ],
                      if (source != null && stage == 2) ...[
                        Text(
                          s.uiReviewImport,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.uiImportReviewHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 20),
                        SoftPanel(
                          tinted: true,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.uiSelectedCount(selected.length),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.uiRecordCount(
                                  selectedHabits.fold(
                                    0,
                                    (n, h) => n + h.records,
                                  ),
                                ),
                                style: TextStyle(color: scheme.primary),
                              ),
                              const SizedBox(height: 12),
                              for (final h in selectedHabits)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        h.type == 0
                                            ? Icons.check_circle_outline
                                            : Icons.water_drop_outlined,
                                        size: 18,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(h.name)),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          label(s, schedules[h.id]),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SectionHeading(s.uiImportRules),
                        Text(s.legacyDifference),
                        const SizedBox(height: 14),
                        Text(
                          s.legacyRecovery,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 18),
                        SoftPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: CheckboxListTile(
                            key: const Key('legacy-acknowledge'),
                            value: acknowledged,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              s.legacyAcknowledge,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            onChanged: working
                                ? null
                                : (v) =>
                                      setState(() => acknowledged = v == true),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                EditorFooter(
                  summary: stage == 1 ? help : null,
                  children: [
                    Expanded(
                      child: AppAction(
                        label: stage == 2
                            ? s.uiBack
                            : stage == 3
                            ? s.uiReturnData
                            : s.cancel,
                        onTap: working
                            ? null
                            : () {
                                if (stage == 2) {
                                  setState(() => stage = 1);
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                      ),
                    ),
                    if (source != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppAction(
                          key: Key(
                            stage == 1 ? 'legacy-next' : 'legacy-commit',
                          ),
                          label: stage == 1 ? s.uiContinue : s.legacyConfirm,
                          primary: true,
                          busy: working,
                          onTap: stage == 1
                              ? (canReview
                                    ? () => setState(() => stage = 2)
                                    : null)
                              : (!working && acknowledged ? commit : null),
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

  Widget _item(BuildContext context, LegacyHabit h) {
    final s = AppLocalizations.of(context);
    final available = !existing.contains(h.id) && h.unsupported == null;
    final checked = selected.contains(h.id);
    final needsRule = checked && !schedules.containsKey(h.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftPanel(
        padding: const EdgeInsets.all(16),
        tinted: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              key: Key('legacy-select-${h.sourceId}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              value: checked,
              title: Text(
                h.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                existing.contains(h.id)
                    ? s.legacyExisting
                    : h.unsupported != null
                    ? s.legacyUnsupported
                    : '${h.type == 0 ? s.checkHabit : s.quantityHabit}${h.archived ? ' · ${s.archived}' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              secondary: ToneIcon(
                h.type == 0
                    ? Icons.auto_stories_outlined
                    : Icons.water_drop_outlined,
                tone: UiTone.violet,
                size: 38,
              ),
              onChanged: working || !available
                  ? null
                  : (v) => setState(() {
                      acknowledged = false;
                      if (v == true) {
                        selected.add(h.id);
                      } else {
                        selected.remove(h.id);
                      }
                    }),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 18,
              runSpacing: 6,
              children: [
                Text(
                  s.uiRecordCount(h.records),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${s.legacySourceFrequency} ${h.numerator}/${h.denominator}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (h.type == 1)
                  Text(
                    '${h.target == null ? '—' : quantityText(h.target!)} ${h.unit}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            if (checked) ...[
              const SizedBox(height: 12),
              if (h.daily)
                Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(s.legacyDaily),
                  ],
                )
              else
                QuietChoice(
                  key: Key('legacy-schedule-${h.sourceId}'),
                  label: needsRule
                      ? s.uiNeedsSchedule
                      : label(s, schedules[h.id]),
                  selected: !needsRule,
                  icon: Icons.calendar_month_outlined,
                  tone: needsRule ? UiTone.peach : UiTone.violet,
                  onTap: working ? null : () => schedule(h),
                ),
            ],
            if (h.unsupported != null) ...[
              const SizedBox(height: 12),
              Text(
                switch (h.unsupported) {
                  'atMost' => s.legacyAtMost,
                  'length' => s.legacyLength,
                  _ => s.legacyTarget,
                },
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: UiTone.peach.ink(context),
                ),
              ),
            ],
            DetailDisclosure(
              title: s.uiShowDetails,
              child: Text(
                '${s.legacyNotes} ${h.notes}\n${s.legacySkips} ${h.skipped}\n${s.legacyIgnored} ${h.ignored}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleEditor extends StatefulWidget {
  const _ScheduleEditor({this.initial});
  final LegacySchedule? initial;
  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  ScheduleKind? kind;
  late final TextEditingController count;
  bool invalid = false;
  @override
  void initState() {
    super.initState();
    kind = widget.initial?.kind;
    count = TextEditingController(text: '${widget.initial?.count ?? 1}');
  }

  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SheetFrame(
      title: s.legacyChooseSchedule,
      icon: Icons.calendar_month_outlined,
      tone: UiTone.peach,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.legacyScheduleHint),
          const SizedBox(height: 16),
          for (final k in ScheduleKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: QuietChoice(
                key: Key('legacy-rule-${k.name}'),
                label: switch (k) {
                  ScheduleKind.weekdays => s.legacyDaily,
                  ScheduleKind.weekly => s.legacyWeekly,
                  ScheduleKind.interval => s.legacyInterval,
                },
                icon: kind == k
                    ? Icons.check_circle_outline
                    : Icons.circle_outlined,
                selected: kind == k,
                onTap: () => setState(() {
                  kind = k;
                  invalid = false;
                }),
              ),
            ),
          if (kind != null && kind != ScheduleKind.weekdays)
            TextField(
              key: const Key('legacy-count'),
              controller: count,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: s.legacyCount,
                errorText: invalid ? s.invalidQuantity : null,
              ),
            ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppAction(
              label: s.cancel,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppAction(
              key: const Key('legacy-rule-save'),
              label: s.save,
              primary: true,
              onTap: kind == null
                  ? null
                  : () {
                      final choice = LegacySchedule(
                        kind!,
                        kind == ScheduleKind.weekdays
                            ? 1
                            : int.tryParse(count.text) ?? 0,
                      );
                      if (choice.valid) {
                        Navigator.pop(context, choice);
                      } else {
                        setState(() => invalid = true);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}
