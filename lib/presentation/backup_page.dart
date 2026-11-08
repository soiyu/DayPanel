import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../data/app_store.dart';
import '../data/document_files.dart';
import '../domain/backup.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'legacy_import.dart';
import 'refined_components.dart';
import 'reminders.dart';
import 'home_widgets.dart';
import '../data/widget_platform.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({
    super.key,
    required this.app,
    this.files,
    this.onReturnToday,
  });
  final AppController app;
  final DocumentFiles? files;
  final VoidCallback? onReturnToday;
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool working = false, committing = false;
  String? message;
  bool failed = false;
  bool restored = false, hasWidgets = false;
  DateTime? lastExport;
  BackupSnapshot? recovery;
  int recoveryEpoch = 0;
  DocumentFiles get files => widget.files ?? AndroidDocumentFiles();
  @override
  void initState() {
    super.initState();
    loadRecovery();
    loadDeviceFacts();
  }

  Future<void> loadDeviceFacts() async {
    final exported = await DeviceExportHistory().lastExport();
    var bound = false;
    final platform = widget.app.widgetPlatform;
    if (platform is WidgetPinning) {
      try {
        bound = await (platform as WidgetPinning).hasWidgets();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        lastExport = exported;
        hasWidgets = bound;
      });
    }
  }

  Future<void> loadRecovery() async {
    try {
      final result = await widget.app.store.readConsistent(
        () async => (
          await widget.app.store.recoverySnapshot(),
          await widget.app.store.generation(),
        ),
      );
      if (mounted) {
        setState(() {
          recovery = result.$1;
          recoveryEpoch = result.$2;
        });
      }
    } catch (_) {}
  }

  Future<void> operate(Future<void> Function() action) async {
    if (working || widget.app.busy) return;
    setState(() {
      working = true;
      message = null;
      failed = false;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() {
          failed = true;
          message = e is BackupInvalid
              ? AppLocalizations.of(context).backupInvalid
              : AppLocalizations.of(context).backupError;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          working = false;
          committing = false;
        });
      }
    }
  }

  Future<void> export() => operate(() async {
    BackupSnapshot? snapshot;
    final ok = await widget.app.run(() async {
      snapshot = await widget.app.store.exportSnapshot();
    });
    if (!ok) throw StateError('Snapshot failed');
    final saved = await files.save(
      snapshot!.encode(),
      'DayPanel-${widget.app.today.key}.json',
    );
    if (saved && mounted) {
      await loadDeviceFacts();
      if (!mounted) return;
      setState(() => message = AppLocalizations.of(context).backupSaved);
    }
  });
  Future<void> import() => operate(() async {
    final epoch = widget.app.generation;
    final bytes = await files.pick();
    if (bytes == null || !mounted) return;
    final snapshot = BackupSnapshot.decode(bytes);
    await confirm(snapshot, epoch: epoch);
  });
  Future<void> confirm(
    BackupSnapshot snapshot, {
    required int epoch,
    bool rollback = false,
  }) async {
    final s = AppLocalizations.of(context);
    final approved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SheetFrame(
        title: rollback ? s.rollbackTitle : s.restorePreview,
        icon: rollback ? Icons.history_rounded : Icons.restore_page_outlined,
        tone: UiTone.peach,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${s.backupDate}\n${MaterialLocalizations.of(ctx).formatFullDate(snapshot.createdAt.toLocal())} ${TimeOfDay.fromDateTime(snapshot.createdAt.toLocal()).format(ctx)}',
            ),
            const SizedBox(height: 16),
            counts(ctx, snapshot),
            const SizedBox(height: 18),
            Text(
              rollback ? s.rollbackBody : s.replaceWarning,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ],
        ),
        footer: Row(
          children: [
            Expanded(
              child: AppAction(
                label: s.cancel,
                onTap: () => Navigator.pop(ctx, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: AppAction(
                label: rollback ? s.rollbackTitle : s.restoreConfirm,
                primary: true,
                onTap: () => Navigator.pop(ctx, true),
              ),
            ),
          ],
        ),
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => committing = true);
    var committed = false;
    final ok = await widget.app.run(() async {
      await widget.app.store.restoreSnapshot(snapshot, rollback: rollback);
      committed = true;
    }, expectedGeneration: epoch);
    if (!mounted) return;
    setState(() {
      failed = !ok;
      restored = ok;
      message = ok
          ? (rollback
                ? AppLocalizations.of(context).rollbackDone
                : AppLocalizations.of(context).restoreDone)
          : committed
          ? s.restoreRefreshFailed
          : s.restoreFailed;
    });
    await loadRecovery();
  }

  Widget counts(BuildContext context, BackupSnapshot snap) {
    final s = AppLocalizations.of(context);
    return SoftPanel(
      tinted: true,
      tone: UiTone.violet,
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          AppBadge('${s.habit} ${snap.count('habits')}'),
          AppBadge('${s.recordsLabel} ${snap.count('entries')}'),
          AppBadge('${s.tasks} ${snap.count('tasks')}', tone: UiTone.peach),
          AppBadge(
            '${s.residentRecords} ${snap.count('task_entries')}',
            tone: UiTone.peach,
          ),
          AppBadge('${s.notes} ${snap.count('notes')}', tone: UiTone.violet),
          AppBadge(
            '${s.cardCollection} ${snap.count('cards')}',
            tone: UiTone.violet,
          ),
          AppBadge('${s.groupsLabel} ${snap.count('habit_groups')}'),
          AppBadge(
            '${s.plansLabel} ${snap.count('plans')}',
            tone: UiTone.violet,
          ),
          AppBadge(
            '${s.remindersTitle} ${snap.count('reminders')}',
            tone: UiTone.peach,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return PopScope(
      canPop: !working,
      child: AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.dataBackup),
            automaticallyImplyLeading: !working,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.backupLocalStatus,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastExport == null
                          ? s.backupNeverExported
                          : '${s.backupLastExport} · ${MaterialLocalizations.of(context).formatMediumDate(lastExport!)} ${TimeOfDay.fromDateTime(lastExport!).format(context)}',
                      key: const Key('device-export-status'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (lastExport != null)
                      Text(
                        s.backupExportFact,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (restored) ...[
                SoftPanel(
                  tone: UiTone.teal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.restoreNextSteps,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (widget.app.reminders.any((r) => r.enabled))
                        SettingRow(
                          icon: Icons.notifications_none_rounded,
                          title: s.restoreCheckReminders,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => RemindersPage(app: widget.app),
                            ),
                          ),
                        ),
                      if (hasWidgets)
                        SettingRow(
                          icon: Icons.widgets_outlined,
                          title: s.restoreWidgets,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => WidgetsHelpPage(
                                app: widget.app,
                                reconnect: true,
                              ),
                            ),
                          ),
                        ),
                      AppAction(
                        label: s.todayLabel,
                        icon: Icons.home_outlined,
                        onTap: () {
                          widget.app.select(widget.app.today);
                          widget.onReturnToday?.call();
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ActionTile(
                key: const Key('export-backup'),
                title: s.exportBackup,
                subtitle: s.uiExportHint,
                icon: Icons.upload_file_outlined,
                emphasized: true,
                onTap: working ? null : export,
                trailing: committing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              ActionTile(
                key: const Key('import-backup'),
                title: s.importBackup,
                subtitle: s.uiRestoreHint,
                icon: Icons.restore_page_outlined,
                tone: UiTone.violet,
                onTap: working ? null : import,
              ),
              const SizedBox(height: 12),
              ActionTile(
                key: const Key('legacy-import'),
                title: s.legacyTitle,
                subtitle: s.uiLegacyHint,
                icon: Icons.move_to_inbox_outlined,
                tone: UiTone.peach,
                onTap: working
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => LegacyImportPage(app: widget.app),
                          ),
                        );
                        await loadRecovery();
                      },
              ),
              if (message != null) ...[
                const SizedBox(height: 18),
                Semantics(
                  liveRegion: true,
                  child: SoftPanel(
                    tinted: true,
                    tone: failed ? UiTone.peach : UiTone.blue,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          failed
                              ? Icons.info_outline
                              : Icons.check_circle_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(message!)),
                      ],
                    ),
                  ),
                ),
              ],
              if (recovery != null) ...[
                SectionHeading(s.rollbackTitle, description: s.uiRecoveryHint),
                ActionTile(
                  key: const Key('rollback-backup'),
                  title: s.rollbackTitle,
                  subtitle: s.rollbackBody,
                  tone: UiTone.peach,
                  icon: Icons.history_rounded,
                  onTap: working
                      ? null
                      : () => operate(
                          () => confirm(
                            recovery!,
                            epoch: recoveryEpoch,
                            rollback: true,
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 20),
              DetailDisclosure(
                title: s.offlineTransferTitle,
                icon: Icons.phonelink_rounded,
                child: Text(
                  s.offlineTransferBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              DetailDisclosure(
                title: s.uiFileScope,
                icon: Icons.shield_outlined,
                child: Text(
                  '${s.backupBody}\n\n${s.exportHint}\n\n${s.restoreHint}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
