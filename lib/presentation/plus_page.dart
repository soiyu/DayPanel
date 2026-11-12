import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';
import 'insights.dart';
import 'home_widgets.dart';
import 'editors.dart';
import 'review_card.dart';
import 'appearance.dart';

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
    // The status request notifies listeners synchronously (busy = true).
    // Defer it so opening this page during a build cannot mark ancestors dirty.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.app.plus.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = widget.app.plus;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

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
                if (p.enabled) ...[
                  // Premium VIP Lifetime Hero Card
                  SoftPanel(
                    tinted: true,
                    tone: UiTone.violet,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6366F1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFFFDE047),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isZh
                                        ? '✦ DayPanel Plus 终身会员'
                                        : '✦ DayPanel Plus Lifetime',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isZh
                                          ? '✓ 终身授权生效中 · 离线可用'
                                          : '✓ Lifetime Active · Offline Ready',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.testing
                              ? s.plusTesting
                              : (isZh
                                    ? '您已永久解锁全部 6 项高级特权，无订阅、无广告，纯本地私密运行。'
                                    : 'All 6 premium privileges unlocked. 100% private, no subscriptions.'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionTitle(
                    isZh ? 'Plus 专属特权直达' : 'Plus Exclusive Privileges',
                    tone: UiTone.violet,
                  ),
                  const SizedBox(height: 8),

                  // 1. Deep Insights
                  _PrivilegeCard(
                    icon: Icons.auto_graph_rounded,
                    title: s.insightsTitle,
                    description: isZh
                        ? '全周期趋势、星期强弱对比、双习惯共现关系与月度节律分析'
                        : s.insightsSubtitle,
                    actionLabel: isZh ? '查看深度洞察' : 'Explore Insights',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => InsightsPage(app: widget.app),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Matrix Widgets
                  _PrivilegeCard(
                    icon: Icons.dashboard_customize_outlined,
                    title: s.panelTitle,
                    description: isZh
                        ? '自由组合 1–4 个打卡/计数/小事，在 Android 桌面一键直达'
                        : 'Combine 1–4 habits & tasks directly on your Android home screen',
                    actionLabel: isZh ? '配置桌面组件' : 'Setup Widgets',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => WidgetsHelpPage(app: widget.app),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Weekly Targets
                  _PrivilegeCard(
                    icon: Icons.date_range_outlined,
                    title: s.weeklyTotalLabel,
                    description: isZh
                        ? '按自然周设定弹性累计目标（如每周运动3次），告别死板每日限制'
                        : 'Set flexible weekly goals (e.g. 3 times/week) without rigid daily pressure',
                    actionLabel: isZh ? '新建周目标习惯' : 'Create Weekly Habit',
                    onAction: () => openEditor(context, widget.app, 'habit'),
                  ),
                  const SizedBox(height: 10),

                  // 4. Detailed Event Ledger
                  _PrivilegeCard(
                    icon: Icons.receipt_long_outlined,
                    title: s.eventTitle,
                    description: isZh
                        ? '精准记录每次喝水毫升数、跑步公里数与具体发生时刻，支持单独纠错'
                        : 'Detailed individual log entries with exact timestamps and notes for corrections',
                  ),
                  const SizedBox(height: 10),

                  // 5. Review Card Export
                  _PrivilegeCard(
                    icon: Icons.insights_outlined,
                    title: s.reviewBuilder,
                    description: isZh
                        ? '精美排版周月成就与手记足迹，高清长图 PNG 导出与分享'
                        : 'Generate beautiful review card images for weekly or monthly milestones',
                    actionLabel: isZh ? '生成复盘长图' : 'Export Review Card',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ReviewCardPage(app: widget.app),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 6. Exclusive Themes & Icons
                  _PrivilegeCard(
                    icon: Icons.palette_outlined,
                    title: s.styleExtra,
                    description: isZh
                        ? '解锁杏黄书斋与海岸清蓝专属组合配色，水墨/耳机/徒步等专属图标'
                        : 'Unlock Apricot and Coastal palettes with premium habit icons',
                    actionLabel: isZh ? '切换专属装扮' : 'Switch Appearance',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AppearancePage(app: widget.app),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftPanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.update_rounded,
                              size: 20,
                              color: UiTone.violet.ink(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isZh
                                    ? '持续迭代优化与终身升级承诺'
                                    : 'Continuous Evolution & Updates',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isZh
                              ? 'DayPanel 由独立开发者持续打磨优化。作为 Plus 终身会员，您将永久享有未来版本中新增的所有 Plus 高级功能、桌面组件、新图表维度与专属装扮，绝无后续订阅与二次收费。'
                              : 'DayPanel is continuously refined. As a Plus Lifetime member, you permanently receive all future Plus features, new widget types, advanced analytics, and exclusive themes for free—no subscriptions, ever.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isZh
                              ? '✓ 100% 离线私密 · 零账号 · 零广告 · 数据完全属于您'
                              : '✓ 100% Offline & Private · No accounts · No ads · Your data stays yours',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: UiTone.teal.ink(context),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.plusBase,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else ...[
                  // Free Edition Upgrade View
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
                    (Icons.auto_graph_rounded, s.insightsTitle),
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
                      onTap: p.available && !p.busy && !p.pending
                          ? p.buy
                          : null,
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
                  const SizedBox(height: 16),
                  SoftPanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.update_rounded,
                              size: 20,
                              color: UiTone.violet.ink(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isZh
                                    ? '持续迭代优化与终身升级承诺'
                                    : 'Continuous Evolution & Updates',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isZh
                              ? 'DayPanel 由独立开发者持续打磨优化。作为 Plus 终身会员，您将永久享有未来版本中新增的所有 Plus 高级功能、桌面组件、新图表维度与专属装扮，绝无后续订阅与二次收费。'
                              : 'DayPanel is continuously refined. As a Plus Lifetime member, you permanently receive all future Plus features, new widget types, advanced analytics, and exclusive themes for free—no subscriptions, ever.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isZh
                              ? '✓ 100% 离线私密 · 零账号 · 零广告 · 数据完全属于您'
                              : '✓ 100% Offline & Private · No accounts · No ads · Your data stays yours',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: UiTone.teal.ink(context),
                                fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _PrivilegeCard extends StatelessWidget {
  const _PrivilegeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: UiTone.violet.ink(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: UiTone.violet.ink(context),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: UiTone.violet.ink(context),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
