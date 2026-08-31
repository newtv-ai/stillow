import 'package:flutter/material.dart';

import '../../domain/sleep_support_review.dart';
import '../../l10n/l10n.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class SleepSupportReviewScreen extends StatefulWidget {
  const SleepSupportReviewScreen({super.key});

  @override
  State<SleepSupportReviewScreen> createState() =>
      _SleepSupportReviewScreenState();
}

class _SleepSupportReviewScreenState extends State<SleepSupportReviewScreen> {
  SleepDifficultyDuration? _duration;
  SleepDifficultyFrequency? _frequency;
  DaytimeImpact? _daytimeImpact;
  SleepOpportunity? _sleepOpportunity;

  SleepSupportReviewAnswers get _answers => SleepSupportReviewAnswers(
    duration: _duration ?? SleepDifficultyDuration.unsure,
    frequency: _frequency ?? SleepDifficultyFrequency.unsure,
    daytimeImpact: _daytimeImpact ?? DaytimeImpact.unsure,
    sleepOpportunity: _sleepOpportunity ?? SleepOpportunity.unsure,
  );

  Future<void> _showResult() async {
    final l10n = context.l10n;
    final guidance = evaluateSleepSupportReview(_answers);
    final considerProfessional =
        guidance == SleepSupportGuidance.considerProfessionalSupport;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                considerProfessional
                    ? l10n.reviewProfessionalTitle
                    : l10n.reviewObserveTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                considerProfessional
                    ? l10n.reviewProfessionalBody
                    : l10n.reviewObserveBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.reviewClinicalContext,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_sleepOpportunity == SleepOpportunity.usuallyNotEnough) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.reviewSleepOpportunityNote,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.reviewBreathingSafety,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.reviewTreatmentNote,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.understood),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                icon: Icons.close_rounded,
                tooltip: l10n.reviewDismiss,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.reviewTitle,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewIntro,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            _ReviewQuestion<SleepDifficultyDuration>(
              title: l10n.reviewDurationQuestion,
              value: _duration,
              onChanged: (value) => setState(() => _duration = value),
              choices: [
                _ReviewChoice(
                  SleepDifficultyDuration.underOneMonth,
                  l10n.reviewUnderMonth,
                ),
                _ReviewChoice(
                  SleepDifficultyDuration.oneToThreeMonths,
                  l10n.reviewOneToThreeMonths,
                ),
                _ReviewChoice(
                  SleepDifficultyDuration.threeMonthsOrMore,
                  l10n.reviewThreeMonths,
                ),
                _ReviewChoice(
                  SleepDifficultyDuration.unsure,
                  l10n.reviewUnsure,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ReviewQuestion<SleepDifficultyFrequency>(
              title: l10n.reviewFrequencyQuestion,
              value: _frequency,
              onChanged: (value) => setState(() => _frequency = value),
              choices: [
                _ReviewChoice(
                  SleepDifficultyFrequency.lessThanWeekly,
                  l10n.reviewLessThanWeekly,
                ),
                _ReviewChoice(
                  SleepDifficultyFrequency.oneOrTwoNights,
                  l10n.reviewOneTwoNights,
                ),
                _ReviewChoice(
                  SleepDifficultyFrequency.threeOrMoreNights,
                  l10n.reviewThreeNights,
                ),
                _ReviewChoice(
                  SleepDifficultyFrequency.unsure,
                  l10n.reviewFrequencyUnsure,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ReviewQuestion<DaytimeImpact>(
              title: l10n.reviewDaytimeQuestion,
              value: _daytimeImpact,
              onChanged: (value) => setState(() => _daytimeImpact = value),
              choices: [
                _ReviewChoice(DaytimeImpact.little, l10n.reviewImpactLittle),
                _ReviewChoice(
                  DaytimeImpact.noticeable,
                  l10n.reviewImpactNoticeable,
                ),
                _ReviewChoice(
                  DaytimeImpact.clearOrUnsafe,
                  l10n.reviewImpactClear,
                ),
                _ReviewChoice(DaytimeImpact.unsure, l10n.reviewUnsure),
              ],
            ),
            const SizedBox(height: 14),
            _ReviewQuestion<SleepOpportunity>(
              title: l10n.reviewOpportunityQuestion,
              value: _sleepOpportunity,
              onChanged: (value) => setState(() => _sleepOpportunity = value),
              choices: [
                _ReviewChoice(
                  SleepOpportunity.usuallyEnough,
                  l10n.reviewOpportunityEnough,
                ),
                _ReviewChoice(
                  SleepOpportunity.varies,
                  l10n.reviewOpportunityVaries,
                ),
                _ReviewChoice(
                  SleepOpportunity.usuallyNotEnough,
                  l10n.reviewOpportunityNotEnough,
                ),
                _ReviewChoice(SleepOpportunity.unsure, l10n.reviewUnsure),
              ],
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _showResult,
              child: Text(l10n.reviewShowResult),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.reviewSkip),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewQuestion<T> extends StatelessWidget {
  const _ReviewQuestion({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.choices,
  });

  final String title;
  final T? value;
  final ValueChanged<T> onChanged;
  final List<_ReviewChoice<T>> choices;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: StillowColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: StillowColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final choice in choices)
              ChoiceChip(
                label: Text(choice.label),
                selected: value == choice.value,
                onSelected: (_) => onChanged(choice.value),
              ),
          ],
        ),
      ],
    ),
  );
}

class _ReviewChoice<T> {
  const _ReviewChoice(this.value, this.label);

  final T value;
  final String label;
}
