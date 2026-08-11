import 'package:flutter/material.dart';

import '../../data/sleep_history_store.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class DataPrivacyScreen extends StatefulWidget {
  const DataPrivacyScreen({super.key, required this.historyStore});

  final SleepHistoryStore historyStore;

  @override
  State<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends State<DataPrivacyScreen> {
  bool _clearing = false;

  Future<void> _clearHistory() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('清除全部睡眠记录？', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(
                '会从这台设备中移除声音陪伴、晨间感受和已同步的健康记录。收藏与个性化偏好不会受影响。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('先留着'),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('全部清除'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    await widget.historyStore.clearAll();
    if (!mounted) return;
    setState(() => _clearing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('这台设备中的睡眠记录已经清除。')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StillowBackdrop(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: QuietIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: '返回',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: 28),
            Text('数据与隐私', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            Text(
              'Stillow 没有账号、网站、服务端或云端同步。以下内容只留在这台设备中，也不会进入系统云备份。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 26),
            const _PrivacyItem(
              icon: Icons.bedtime_outlined,
              title: '极简本地记录',
              body: '最多保存 30 天的声音陪伴、播放时长、睡前或夜醒场景，以及你主动选择的晨间感受。卸载或换机后不会恢复。',
            ),
            const SizedBox(height: 12),
            const _PrivacyItem(
              icon: Icons.watch_outlined,
              title: '健康数据需要你主动连接',
              body:
                  '只保存睡眠时段和阶段；不保留健康记录 UUID、来源设备名、心率或 HRV，不写入健康平台，不后台同步。断开后会清除 App 中的健康缓存。',
            ),
            const SizedBox(height: 12),
            const _PrivacyItem(
              icon: Icons.auto_awesome_outlined,
              title: '梦境文字不保存',
              body: '梦境解析只在当前页面完成。退出解析页后，输入的梦境文字不会写入本地记录。',
            ),
            const SizedBox(height: 12),
            const _PrivacyItem(
              icon: Icons.insights_outlined,
              title: '趋势不是诊断',
              body: '设备记录和晨间感受只用于轻松回顾，不生成医学睡眠评分，也不用于诊断或治疗。',
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: _clearing ? null : _clearHistory,
              icon: _clearing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: const Text('清除全部睡眠记录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: StillowColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: StillowColors.outline),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: StillowColors.sage),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}
