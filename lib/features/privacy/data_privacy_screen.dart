import 'package:flutter/material.dart';

import '../../data/sleep_history_store.dart';
import '../../l10n/l10n.dart';
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
    final l10n = context.l10n;
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
              Text(
                l10n.privacyClearTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.privacyClearBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.keepForNow),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.clearAll),
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
    ).showSnackBar(SnackBar(content: Text(l10n.historyCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                tooltip: l10n.back,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.privacyTitle,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.privacyIntro,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 26),
            _PrivacyItem(
              icon: Icons.bedtime_outlined,
              title: l10n.privacyLocalTitle,
              body: l10n.privacyLocalBody,
            ),
            const SizedBox(height: 12),
            _PrivacyItem(
              icon: Icons.audio_file_outlined,
              title: l10n.privacyUserSoundsTitle,
              body: l10n.privacyUserSoundsBody,
            ),
            const SizedBox(height: 12),
            _PrivacyItem(
              icon: Icons.watch_outlined,
              title: l10n.privacyHealthTitle,
              body: l10n.privacyHealthBody,
            ),
            const SizedBox(height: 12),
            _PrivacyItem(
              icon: Icons.auto_awesome_outlined,
              title: l10n.privacyDreamTitle,
              body: l10n.privacyDreamBody,
            ),
            const SizedBox(height: 12),
            _PrivacyItem(
              icon: Icons.insights_outlined,
              title: l10n.privacyTrendTitle,
              body: l10n.privacyTrendBody,
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
              label: Text(l10n.clearSleepHistory),
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
