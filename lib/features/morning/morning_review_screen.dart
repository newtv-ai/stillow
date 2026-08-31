import 'package:flutter/material.dart';

import '../../domain/sleep_history.dart';
import '../../l10n/l10n.dart';
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
    final l10n = context.l10n;
    final summary = switch (_feeling) {
      MorningFeeling.rested => l10n.morningRestedSummary,
      MorningFeeling.ordinary => l10n.morningOrdinarySummary,
      MorningFeeling.tired => l10n.morningTiredSummary,
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
                tooltip: l10n.back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.morningTitle,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.morningSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeelingChip(
                  label: l10n.feelingRested,
                  selected: _feeling == MorningFeeling.rested,
                  onTap: () {
                    _choose(MorningFeeling.rested);
                  },
                ),
                _FeelingChip(
                  label: l10n.feelingOrdinary,
                  selected: _feeling == MorningFeeling.ordinary,
                  onTap: () {
                    _choose(MorningFeeling.ordinary);
                  },
                ),
                _FeelingChip(
                  label: l10n.feelingTired,
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
                          ? l10n.morningSubjectiveOnly
                          : _saving
                          ? l10n.morningSaving
                          : l10n.morningSaved,
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
                    l10n.morningDreamTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.morningDreamBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DreamInterpretationScreen(),
                      ),
                    ),
                    child: Text(l10n.morningDreamAction),
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
