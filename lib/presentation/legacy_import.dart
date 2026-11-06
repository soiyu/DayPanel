import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../data/app_store.dart';
import '../data/legacy_files.dart';
import '../domain/legacy_import.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';

class LegacyImportPage extends StatefulWidget {
  const LegacyImportPage({super.key, required this.app, this.files});
  final AppController app;
  final LegacyFiles? files;
  @override
  State<LegacyImportPage> createState() => _LegacyImportPageState();
}

class _LegacyImportPageState extends State<LegacyImportPage> {
  LegacyImport? source;
  int epoch = 0;
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
          acknowledged = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          source = null;
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
    if (choice != null && mounted) setState(() => schedules[h.id] = choice);
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
      if (ok || committed) source = null;
    });
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
    final ready =
        !working &&
        selected.isNotEmpty &&
        acknowledged &&
        selected.every(schedules.containsKey);
    return PopScope(
      canPop: !working,
      child: AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.legacyTitle),
            automaticallyImplyLeading: !working,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      SoftPanel(
                        tinted: true,
                        tone: UiTone.violet,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ToneIcon(
                              Icons.move_to_inbox_outlined,
                              tone: UiTone.violet,
                              size: 52,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.legacyIntro,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(s.legacySupported),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppAction(
                        key: const Key('legacy-pick'),
                        label: s.legacyPick,
                        icon: Icons.folder_open,
                        primary: true,
                        busy: working,
                        onTap: working ? null : pick,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        SoftPanel(tinted: true, child: Text(message!)),
                      ],
                      if (source != null) ...[
                        SectionTitle(
                          s.legacyReview,
                          count: source!.habits.length,
                          tone: UiTone.violet,
                        ),
                        Text(s.legacyDifference),
                        const SizedBox(height: 14),
                        Text(s.legacyRecovery),
                        const SizedBox(height: 18),
                        if (selected.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(s.legacyEmpty),
                          ),
                        for (final h in source!.habits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SoftPanel(
                              padding: const EdgeInsets.all(14),
                              tinted: selected.contains(h.id),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CheckboxListTile(
                                    key: Key('legacy-select-${h.sourceId}'),
                                    contentPadding: EdgeInsets.zero,
                                    value: selected.contains(h.id),
                                    title: Text(h.name),
                                    subtitle: Text(
                                      existing.contains(h.id)
                                          ? s.legacyExisting
                                          : h.unsupported != null
                                          ? s.legacyUnsupported
                                          : '${h.type == 0 ? s.checkHabit : s.quantityHabit}${h.archived ? ' · ${s.archived}' : ''}',
                                    ),
                                    onChanged:
                                        working ||
                                            existing.contains(h.id) ||
                                            h.unsupported != null
                                        ? null
                                        : (v) => setState(() {
                                            if (v == true) {
                                              selected.add(h.id);
                                            } else {
                                              selected.remove(h.id);
                                            }
                                          }),
                                  ),
                                  Text(
                                    '${s.legacySourceFrequency}  ${h.numerator}/${h.denominator}',
                                  ),
                                  if (h.type == 1)
                                    Text(
                                      '${s.target} ${h.target == null ? '—' : quantityText(h.target!)} ${h.unit}',
                                    ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      AppBadge(
                                        '${s.legacyRecords} ${h.records}',
                                      ),
                                      AppBadge(
                                        '${s.legacyNotes} ${h.notes}',
                                        tone: UiTone.violet,
                                      ),
                                      if (h.skipped > 0)
                                        AppBadge(
                                          '${s.legacySkips} ${h.skipped}',
                                          tone: UiTone.peach,
                                        ),
                                      if (h.ignored > 0)
                                        AppBadge(
                                          '${s.legacyIgnored} ${h.ignored}',
                                          tone: UiTone.peach,
                                        ),
                                    ],
                                  ),
                                  if (h.unsupported != null) ...[
                                    const SizedBox(height: 12),
                                    Text(switch (h.unsupported) {
                                      'atMost' => s.legacyAtMost,
                                      'length' => s.legacyLength,
                                      _ => s.legacyTarget,
                                    }),
                                  ],
                                  if (selected.contains(h.id)) ...[
                                    const SizedBox(height: 12),
                                    if (h.daily)
                                      Text(s.legacyDaily)
                                    else
                                      AppAction(
                                        key: Key(
                                          'legacy-schedule-${h.sourceId}',
                                        ),
                                        label: label(s, schedules[h.id]),
                                        tone: UiTone.peach,
                                        onTap: working
                                            ? null
                                            : () => schedule(h),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        CheckboxListTile(
                          key: const Key('legacy-acknowledge'),
                          value: acknowledged,
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.legacyAcknowledge),
                          onChanged: working
                              ? null
                              : (v) => setState(() => acknowledged = v == true),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppAction(
                          label: s.cancel,
                          onTap: working ? null : () => Navigator.pop(context),
                        ),
                      ),
                      if (source != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AppAction(
                            key: const Key('legacy-commit'),
                            label: s.legacyConfirm,
                            primary: true,
                            busy: working,
                            onTap: ready ? commit : null,
                          ),
                        ),
                      ],
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
              child: AppAction(
                key: Key('legacy-rule-${k.name}'),
                label: switch (k) {
                  ScheduleKind.weekdays => s.legacyDaily,
                  ScheduleKind.weekly => s.legacyWeekly,
                  ScheduleKind.interval => s.legacyInterval,
                },
                icon: kind == k ? Icons.check_circle_outline : null,
                primary: kind == k,
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
