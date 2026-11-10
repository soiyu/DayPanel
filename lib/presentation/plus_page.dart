import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';

Future<bool> requirePlus(BuildContext context, AppController app) async {
  if (app.plus.enabled) return true;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => PlusPage(app: app)),
  );
  return app.plus.enabled;
}

class PlusPage extends StatefulWidget {
  const PlusPage({super.key, required this.app});
  final AppController app;
  @override
  State<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends State<PlusPage> {
  @override
  void initState() {
    super.initState();
    widget.app.plus.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = widget.app.plus;
    return AnimatedBuilder(
      animation: p,
      builder: (context, _) => AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.plusTitle)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SoftPanel(
                  tinted: true,
                  tone: UiTone.violet,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_outlined, size: 36),
                      const SizedBox(height: 16),
                      Text(
                        p.testing
                            ? s.plusTesting
                            : p.owned
                            ? s.plusOwned
                            : s.plusDescription,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final row in [
                  (Icons.dashboard_customize_outlined, s.panelTitle),
                  (Icons.receipt_long_outlined, s.eventTitle),
                  (Icons.date_range_outlined, s.weeklyTotalLabel),
                  (Icons.insights_outlined, s.reviewBuilder),
                  (Icons.palette_outlined, s.styleExtra),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(row.$1, color: UiTone.violet.ink(context)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(row.$2)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(s.plusBase),
                const SizedBox(height: 24),
                if (p.pending) Text(s.plusPending),
                if (p.error != null)
                  Text(
                    p.error == 'cancelled'
                        ? s.plusCancelled
                        : s.plusUnavailable,
                  ),
                if (!p.testing && !p.owned)
                  AppAction(
                    label: p.price == null
                        ? s.plusUnavailable
                        : '${s.plusBuy} · ${p.price}',
                    primary: true,
                    busy: p.busy,
                    onTap: p.available && !p.busy && !p.pending ? p.buy : null,
                  ),
                const SizedBox(height: 12),
                AppAction(
                  label: s.plusRestore,
                  icon: Icons.restore_rounded,
                  busy: p.busy,
                  onTap: p.busy ? null : p.restore,
                ),
                const SizedBox(height: 12),
                AppAction(label: s.retry, onTap: p.busy ? null : p.refresh),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
