import 'package:flutter/material.dart';

import '../../domain/stillow_models.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.initialProfile,
  });

  final Future<void> Function(UserProfile profile) onComplete;
  final UserProfile? initialProfile;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  SupportNeed? _supportNeed;
  SoundPreference? _soundPreference;
  GuidancePreference? _guidancePreference;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _supportNeed = profile?.supportNeed;
    _soundPreference = profile?.soundPreference;
    _guidancePreference = profile?.guidancePreference;
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    await widget.onComplete(
      (widget.initialProfile ?? const UserProfile()).copyWith(
        onboardingComplete: true,
        supportNeed: _supportNeed ?? SupportNeed.quietMind,
        soundPreference: _soundPreference ?? SoundPreference.minimal,
        guidancePreference:
            _guidancePreference ?? GuidancePreference.occasional,
      ),
    );
  }

  void _advance() {
    if (_step == 2) {
      _finish();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StillowBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_step > 0)
                      QuietIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: '返回',
                        onPressed: _back,
                      )
                    else
                      const StillowWordmark(),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : _finish,
                      child: Text(
                        widget.initialProfile == null ? '先随便听听' : '保留现在',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 16),
                _StepDots(step: _step),
                SizedBox(height: compact ? 12 : 18),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.025, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      child: _buildStep(compact: compact),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 8 : 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(compact ? 50 : 54),
                  ),
                  onPressed: _saving || !_canContinue ? null : _advance,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _saving
                        ? const SizedBox(
                            key: ValueKey('saving'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _step == 2 ? '今晚先试试' : '继续',
                            key: ValueKey(_step),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool get _canContinue {
    return switch (_step) {
      0 => _supportNeed != null,
      1 => _soundPreference != null,
      2 => _guidancePreference != null,
      _ => false,
    };
  }

  Widget _buildStep({required bool compact}) {
    return switch (_step) {
      0 => _ChoiceStep<SupportNeed>(
        title: '今晚，你更希望得到哪种陪伴？',
        subtitle: '没有标准答案，只选最接近此刻的感受。',
        value: _supportNeed,
        compact: compact,
        onChanged: (value) => setState(() => _supportNeed = value),
        choices: const [
          _Choice(
            value: SupportNeed.quietMind,
            title: '想法停不下来',
            icon: Icons.cloud_outlined,
          ),
          _Choice(
            value: SupportNeed.notSleepy,
            title: '脑袋没想什么，但还不困',
            icon: Icons.visibility_outlined,
          ),
          _Choice(
            value: SupportNeed.sleepPressure,
            title: '越想赶快睡，反而越清醒',
            icon: Icons.hourglass_empty_rounded,
          ),
          _Choice(
            value: SupportNeed.relaxBody,
            title: '让身体松下来',
            icon: Icons.spa_outlined,
          ),
          _Choice(
            value: SupportNeed.maskNoise,
            title: '把周围动静放远一点',
            icon: Icons.water_drop_outlined,
          ),
          _Choice(
            value: SupportNeed.nightAwake,
            title: '夜里醒来后，不容易再睡',
            icon: Icons.nights_stay_outlined,
          ),
          _Choice(
            value: SupportNeed.gentleCompany,
            title: '说不上来，只想有人陪一会儿',
            icon: Icons.nights_stay_outlined,
          ),
        ],
      ),
      1 => _ChoiceStep<SoundPreference>(
        title: '什么声音会让你舒服一些？',
        subtitle: '以后随时可以换，不需要现在就确定。',
        value: _soundPreference,
        compact: compact,
        onChanged: (value) => setState(() => _soundPreference = value),
        choices: const [
          _Choice(
            value: SoundPreference.softVoice,
            title: '轻轻说话，或不必听懂的课程',
            icon: Icons.graphic_eq_rounded,
          ),
          _Choice(
            value: SoundPreference.familiarMusic,
            title: '熟悉、平缓的音乐',
            icon: Icons.music_note_rounded,
          ),
          _Choice(
            value: SoundPreference.nature,
            title: '雨声、风声等环境声',
            icon: Icons.grain_rounded,
          ),
          _Choice(
            value: SoundPreference.minimal,
            title: '更喜欢安静，只要少量提示',
            icon: Icons.volume_down_outlined,
          ),
        ],
      ),
      _ => _ChoiceStep<GuidancePreference>(
        title: '你喜欢怎样的陪伴？',
        subtitle: '不喜欢被指导，也完全没关系。',
        value: _guidancePreference,
        compact: compact,
        onChanged: (value) => setState(() => _guidancePreference = value),
        choices: const [
          _Choice(
            value: GuidancePreference.stepByStep,
            title: '带着我一步步放松',
            icon: Icons.route_outlined,
          ),
          _Choice(
            value: GuidancePreference.occasional,
            title: '偶尔提醒一下就好',
            icon: Icons.more_horiz_rounded,
          ),
          _Choice(
            value: GuidancePreference.ambientOnly,
            title: '不要指导，让声音陪着就好',
            icon: Icons.air_rounded,
          ),
        ],
      ),
    };
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: index == step ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: index <= step ? StillowColors.sage : StillowColors.outline,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _ChoiceStep<T> extends StatelessWidget {
  const _ChoiceStep({
    required this.title,
    required this.subtitle,
    required this.choices,
    required this.value,
    required this.onChanged,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final List<_Choice<T>> choices;
  final T? value;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: compact
              ? Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 27, height: 1.18)
              : Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: compact
              ? Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.4)
              : Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: compact ? 12 : 18),
        for (var index = 0; index < choices.length; index++) ...[
          SoftChoiceCard(
            title: choices[index].title,
            icon: choices[index].icon,
            selected: value == choices[index].value,
            dense: true,
            onTap: () => onChanged(choices[index].value),
          ),
          if (index != choices.length - 1) SizedBox(height: compact ? 8 : 10),
        ],
      ],
    );
  }
}

class _Choice<T> {
  const _Choice({required this.value, required this.title, required this.icon});

  final T value;
  final String title;
  final IconData icon;
}
