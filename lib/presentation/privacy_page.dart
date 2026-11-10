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
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    String t(String a, String b) => zh ? a : b;
    final rows = <String, String>{
      t('本机数据', 'On-device data'): t(
        '习惯、每次记录、任务、手记、卡片和外观保存在这台设备。DayPanel不提供云同步，不要求注册账号，不接入广告或分析SDK。',
        'Habits, individual records, tasks, notes, cards and appearance are stored on this device. DayPanel has no cloud synchronization, developer account, advertising or analytics SDK.',
      ),
      t('购买', 'Purchases'): t(
        'Plus由Google Play处理付款。DayPanel读取并验证商店收据以恢复权益，不读取银行卡资料。收据与业务备份分开保存；离线可使用已经验证的权益，联网后可重新核对。',
        'Google Play processes Plus payments. DayPanel reads and verifies store receipts to restore access; it does not receive card details. Receipts are separate from your data backup. Previously verified access can work offline and is checked again when the store is available.',
      ),
      t('导出、分享与日历', 'Export, sharing and calendar'): t(
        '只有你发起时才将选定文件交给系统保存或分享，或将日历事件草稿交给日历应用。请在预览和系统页面核对内容。其它应用、日历账号或文件提供方使用自己的隐私政策。',
        'Only your explicit actions hand a file to system storage/sharing, or an event draft to a calendar app. Review the content first. Receiving apps, calendar accounts and document providers have their own policies.',
      ),
      t('删除与保留', 'Deleting your data'): t(
        '可以在App中删除内容，或通过系统应用设置清除存储/卸载删除本机数据。恢复前副本用于回退，会被下一次恢复替换。你导出到App外的文件及日历副本需要在相应位置自行删除。已获卡片保留解锁时快照，删除习惯不会删除卡片；可单独管理卡片。',
        'You can delete content in the app, or clear app storage/uninstall to remove on-device data. The pre-restore copy is replaced by the next restore. Delete externally exported files and calendar copies separately. Earned cards keep their original snapshots when a habit is deleted.',
      ),
    };
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t('隐私与支持', 'Privacy & support'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (info['version'] != null)
                Text('DayPanel ${info['version']} (${info['code']})'),
              for (final row in rows.entries) ...[
                const SizedBox(height: 20),
                Text(row.key, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(row.value),
              ],
              if ((info['privacy'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 20),
                AppAction(
                  label: t('查看公开隐私政策', 'View published privacy policy'),
                  onTap: () => open('privacy'),
                ),
              ],
              if ((info['support'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                AppAction(
                  label: t('联系支持', 'Contact support'),
                  onTap: () => open('support'),
                ),
              ],
              if (error != null) Text(error!),
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
