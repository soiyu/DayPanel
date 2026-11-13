import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components.dart';
import 'theme.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  static const channel = MethodChannel('app.daypanel.next/about');
  Map<String, Object?> info = {};
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await channel.invokeMapMethod<String, Object?>('info');
      if (mounted) setState(() => info = data ?? {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    String t(String a, String b) => zh ? a : b;

    final sections = <_PrivacySection>[
      _PrivacySection(
        icon: Icons.shield_outlined,
        title: t('本机私密存储', '100% Local & Private'),
        body: t(
          '您的习惯、打卡记录、小事清单、手记与成就卡片完全保存在当前设备。DayPanel 不提供任何云端同步，无需注册账号，不接入任何第三方广告或数据统计追踪。',
          'All your habits, logs, tasks, notes and cards stay strictly on this device. DayPanel requires no account, does not sync to the cloud, and contains zero ads or third-party tracking.',
        ),
      ),
      _PrivacySection(
        icon: Icons.verified_user_outlined,
        title: t('购买凭证安全', 'Purchase Security'),
        body: t(
          'Plus 终身授权由应用商店官方渠道处理与结算。DayPanel 仅在本地验证购买凭证以激活会员权益，绝不接触银行卡或支付信息。离线时已验证的权益依然可用，连接网络后可随时一键恢复。',
          'Plus lifetime access is handled by the official store. DayPanel only verifies store receipts to unlock features and never receives payment details. Verified access remains available offline and can be restored anytime.',
        ),
      ),
      _PrivacySection(
        icon: Icons.folder_shared_outlined,
        title: t('自主掌控与导出', 'Your Data, Your Control'),
        body: t(
          '仅在您主动发起导出备份、分享卡片或同步日历时，系统才会调用相应功能。导出的备份文件由您完全掌控，建议保存在私密安全的个人存储中。',
          'Files are exported, cards shared, and calendar events created only upon your direct action. Your exported files belong entirely to you.',
        ),
      ),
      _PrivacySection(
        icon: Icons.auto_delete_outlined,
        title: t('数据删除与清除', 'Data Deletion'),
        body: t(
          '您可以随时在应用内单项删除记录，或通过手机系统“清除存储空间”或卸载应用彻底抹除所有本地数据。已获得的成就卡片保留当时的精美快照，删除习惯不会影响已生成的卡片。',
          'You can delete records inside the app anytime, or erase local data via system settings or uninstalling. Unlocked cards retain their original milestone snapshots.',
        ),
      ),
    ];

    final hasPrivacyUrl = (info['privacy'] as String? ?? '').isNotEmpty;
    final hasSupportEmail = (info['support'] as String? ?? '').isNotEmpty;

    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t('隐私与支持', 'Privacy & support'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              SoftPanel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: UiTone.violet
                            .ink(context)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        color: UiTone.violet.ink(context),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DayPanel',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info['version'] != null
                                ? 'v${info['version']}'
                                : t('纯本地日常记录', 'Offline daily tracker'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final section in sections) ...[
                SoftPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            section.icon,
                            size: 18,
                            color: UiTone.violet.ink(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              section.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SoftPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 18,
                          color: UiTone.violet.ink(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t('意见反馈与支持', 'Feedback & Support'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t(
                        '如果您在使用过程中有任何疑问、建议或需要支持，欢迎联系我们。我们致力于为您提供纯净、无打扰的离线记录体验。',
                        'If you have questions, feedback or need assistance, feel free to reach out. We are dedicated to providing a clean, distraction-free experience.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                    if (hasSupportEmail) ...[
                      const SizedBox(height: 12),
                      AppAction(
                        label: t('联系支持', 'Contact support'),
                        tone: UiTone.violet,
                        onTap: () => open('support'),
                      ),
                    ],
                    if (hasPrivacyUrl) ...[
                      const SizedBox(height: 8),
                      AppAction(
                        label: t('查看公开隐私政策', 'View published privacy policy'),
                        onTap: () => open('privacy'),
                      ),
                    ],
                  ],
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> open(String action) async {
    try {
      await channel.invokeMethod<void>(action);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = Localizations.localeOf(context).languageCode == 'zh'
              ? '暂时无法打开，请稍后再试。'
              : 'Could not open this page. Please try again.',
        );
      }
    }
  }
}

class _PrivacySection {
  const _PrivacySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
