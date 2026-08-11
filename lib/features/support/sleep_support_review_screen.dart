import 'package:flutter/material.dart';

import '../../domain/sleep_support_review.dart';
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
                considerProfessional ? '值得请专业人士一起看看' : '暂时不用急着给它贴标签',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                considerProfessional
                    ? '你的选择里出现了持续、频繁或已经影响白天状态的信号。预约睡眠门诊、全科或熟悉睡眠问题的专业人士，会比继续只换声音更合适。'
                    : '这些选择还不足以说明是慢性失眠。可以继续留意自己的实际感受；如果困扰加重，或你只是希望有人一起梳理，也随时可以咨询专业人士。',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 14),
              Text(
                '临床评估通常会一起考虑：困难是否每周大约 3 晚或更多、是否持续约 3 个月或更久、白天是否受影响，以及是否已经有足够的睡眠时间和合适环境。这里没有做诊断，也没有生成分数。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_sleepOpportunity == SleepOpportunity.usuallyNotEnough) ...[
                const SizedBox(height: 12),
                Text(
                  '你也提到最近常常没有留出足够睡眠时间。先尽量照顾这个现实条件会有帮助；如果做不到或白天已经很难受，同样可以向专业人士求助。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '如果经常憋醒、喘醒、被观察到呼吸暂停，或困倦已经影响驾驶安全，不用等待这个回顾的结果，请尽早就医确认。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '专业评估可能讨论 CBT-I、其他睡眠问题和必要时的药物；药物不是 App 自动给出的默认答案。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('我知道了'),
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
                tooltip: '暂不回顾',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 18),
            Text('一起轻轻回顾一下', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              '这不是考试，也不会给你贴标签。可以只选愿意回答的；选择仅用于当前页面，退出后不保存。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            _ReviewQuestion<SleepDifficultyDuration>(
              title: '这样的入睡或夜醒困难，大概持续多久了？',
              value: _duration,
              onChanged: (value) => setState(() => _duration = value),
              choices: const [
                _ReviewChoice(SleepDifficultyDuration.underOneMonth, '不到 1 个月'),
                _ReviewChoice(
                  SleepDifficultyDuration.oneToThreeMonths,
                  '1～3 个月',
                ),
                _ReviewChoice(
                  SleepDifficultyDuration.threeMonthsOrMore,
                  '3 个月以上',
                ),
                _ReviewChoice(SleepDifficultyDuration.unsure, '不太确定'),
              ],
            ),
            const SizedBox(height: 14),
            _ReviewQuestion<SleepDifficultyFrequency>(
              title: '最近一周里，大概有几个晚上会遇到？',
              value: _frequency,
              onChanged: (value) => setState(() => _frequency = value),
              choices: const [
                _ReviewChoice(
                  SleepDifficultyFrequency.lessThanWeekly,
                  '不到每周一次',
                ),
                _ReviewChoice(
                  SleepDifficultyFrequency.oneOrTwoNights,
                  '每周 1～2 晚',
                ),
                _ReviewChoice(
                  SleepDifficultyFrequency.threeOrMoreNights,
                  '每周 3 晚或更多',
                ),
                _ReviewChoice(SleepDifficultyFrequency.unsure, '说不准'),
              ],
            ),
            const SizedBox(height: 14),
            _ReviewQuestion<DaytimeImpact>(
              title: '它对白天的精神、注意力或情绪有什么影响？',
              value: _daytimeImpact,
              onChanged: (value) => setState(() => _daytimeImpact = value),
              choices: const [
                _ReviewChoice(DaytimeImpact.little, '几乎没有'),
                _ReviewChoice(DaytimeImpact.noticeable, '能感觉到一些'),
                _ReviewChoice(DaytimeImpact.clearOrUnsafe, '影响比较明显或安全'),
                _ReviewChoice(DaytimeImpact.unsure, '不太确定'),
              ],
            ),
            const SizedBox(height: 14),
            _ReviewQuestion<SleepOpportunity>(
              title: '通常已经留出了够用的睡眠时间和相对合适的环境吗？',
              value: _sleepOpportunity,
              onChanged: (value) => setState(() => _sleepOpportunity = value),
              choices: const [
                _ReviewChoice(SleepOpportunity.usuallyEnough, '大多数时候有'),
                _ReviewChoice(SleepOpportunity.varies, '有时有，有时没有'),
                _ReviewChoice(SleepOpportunity.usuallyNotEnough, '大多数时候没有'),
                _ReviewChoice(SleepOpportunity.unsure, '不太确定'),
              ],
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _showResult,
              child: const Text('这样就好，看看说明'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('先不回顾'),
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
