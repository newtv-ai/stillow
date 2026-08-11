import 'package:flutter/material.dart';

import '../../domain/sleep_history.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';
import 'dream_interpretation_screen.dart';

class MorningReviewScreen extends StatefulWidget {
  const MorningReviewScreen({super.key, this.onFeelingSelected});

  final Future<void> Function(MorningFeeling feeling)? onFeelingSelected;

  @override
  State<MorningReviewScreen> createState() => _MorningReviewScreenState();
}

class _MorningReviewScreenState extends State<MorningReviewScreen> {
  MorningFeeling? _feeling;
  bool _saving = false;

  Future<void> _choose(MorningFeeling feeling) async {
    if (_saving) return;
    setState(() {
      _feeling = feeling;
      _saving = widget.onFeelingSelected != null;
    });
    await widget.onFeelingSelected?.call(feeling);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final summary = switch (_feeling) {
      MorningFeeling.rested => '今天似乎恢复得还不错。',
      MorningFeeling.ordinary => '今天的恢复感比较普通。',
      MorningFeeling.tired => '昨晚似乎没有休息得很舒服。',
      null => null,
    };

    return Scaffold(
      body: StillowBackdrop(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: QuietIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: '返回',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '醒来以后，\n感觉怎么样？',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              '只凭现在的感觉选一个。没有标准答案。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeelingChip(
                  label: '挺有精神',
                  selected: _feeling == MorningFeeling.rested,
                  onTap: () {
                    _choose(MorningFeeling.rested);
                  },
                ),
                _FeelingChip(
                  label: '还算普通',
                  selected: _feeling == MorningFeeling.ordinary,
                  onTap: () {
                    _choose(MorningFeeling.ordinary);
                  },
                ),
                _FeelingChip(
                  label: '还是有点累',
                  selected: _feeling == MorningFeeling.tired,
                  onTap: () {
                    _choose(MorningFeeling.tired);
                  },
                ),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: StillowColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: StillowColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.onFeelingSelected == null
                          ? '这是你此刻的主观感受，不是睡眠分数。'
                          : _saving
                          ? '正在轻轻留在这台设备中…'
                          : '这是主观感受，不是睡眠分数。已留在这台设备中，最多保留 30 天。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B3D38), Color(0xFF202D2A)],
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    color: StillowColors.moon,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '还记得昨晚的梦吗？',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '写几个画面，得到一份轻松的娱乐解析。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DreamInterpretationScreen(),
                      ),
                    ),
                    child: const Text('看看我的梦'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeelingChip extends StatelessWidget {
  const _FeelingChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
