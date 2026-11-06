import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../data/app_store.dart';
import '../data/document_files.dart';
import '../domain/backup.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key, required this.app, this.files});
  final AppController app;
  final DocumentFiles? files;
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool working = false, committing = false;
  String? message;
  bool failed = false;
  BackupSnapshot? recovery;
  DocumentFiles get files => widget.files ?? AndroidDocumentFiles();
  @override
  void initState() {
    super.initState();
    loadRecovery();
  }

  Future<void> loadRecovery() async {
    try {
      final r = await widget.app.store.recoverySnapshot();
      if (mounted) setState(() => recovery = r);
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
            padding: const EdgeInsets.all(20),
            children: [
              SoftPanel(
                tinted: true,
                tone: UiTone.blue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ToneIcon(Icons.shield_outlined, size: 52),
                    const SizedBox(height: 16),
                    Text(
                      s.backupLocal,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(s.backupBody),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              AppAction(
                key: const Key('export-backup'),
                label: s.exportBackup,
                icon: Icons.file_upload_outlined,
                primary: true,
                busy: committing,
                onTap: working ? null : export,
              ),
              const SizedBox(height: 10),
              Text(s.exportHint, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 22),
              AppAction(
                key: const Key('import-backup'),
                label: s.importBackup,
                icon: Icons.file_download_outlined,
                tone: UiTone.violet,
                onTap: working ? null : import,
              ),
              const SizedBox(height: 10),
              Text(s.restoreHint, style: Theme.of(context).textTheme.bodySmall),
              if (message != null) ...[
                const SizedBox(height: 18),
                SoftPanel(
                  tinted: true,
                  tone: failed ? UiTone.peach : UiTone.blue,
                  child: Text(message!),
                ),
              ],
              if (recovery != null) ...[
                const SizedBox(height: 24),
                SectionTitle(s.rollbackTitle, tone: UiTone.peach),
                SoftPanel(
                  tinted: true,
                  tone: UiTone.peach,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.rollbackBody,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      AppAction(
                        key: const Key('rollback-backup'),
                        label: s.rollbackTitle,
                        icon: Icons.history_rounded,
                        tone: UiTone.peach,
                        onTap: working
                            ? null
                            : () => operate(
                                () => confirm(
                                  recovery!,
                                  epoch: widget.app.generation,
                                  rollback: true,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
