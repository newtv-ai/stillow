import 'package:flutter/material.dart';

import '../../domain/stillow_models.dart';
import '../../l10n/l10n.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.initialProfile,
    this.hasGuidedRelaxation = false,
  });

  final Future<void> Function(UserProfile profile) onComplete;
  final UserProfile? initialProfile;
  final bool hasGuidedRelaxation;

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
    final guidance = profile?.guidancePreference;
    _guidancePreference =
        !widget.hasGuidedRelaxation && guidance == GuidancePreference.stepByStep
        ? null
        : guidance;
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
    final l10n = context.l10n;
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
                        tooltip: l10n.back,
                        onPressed: _back,
                      )
                    else
                      const StillowWordmark(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _saving ? null : _finish,
                          child: Text(
                            widget.initialProfile?.onboardingComplete == true
                                ? l10n.onboardingKeep
                                : l10n.onboardingSkip,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                            _step == 2
                                ? l10n.onboardingTryTonight
                                : l10n.continueLabel,
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
    final l10n = context.l10n;
    return switch (_step) {
      0 => _ChoiceStep<SupportNeed>(
        title: l10n.onboardingNeedTitle,
        subtitle: l10n.onboardingNeedSubtitle,
        value: _supportNeed,
        compact: compact,
        onChanged: (value) => setState(() => _supportNeed = value),
        choices: [
          _Choice(
            value: SupportNeed.quietMind,
            title: l10n.needQuietMind,
            icon: Icons.cloud_outlined,
          ),
          _Choice(
            value: SupportNeed.notSleepy,
            title: l10n.needNotSleepy,
            icon: Icons.visibility_outlined,
          ),
          _Choice(
            value: SupportNeed.sleepPressure,
            title: l10n.needSleepPressure,
            icon: Icons.hourglass_empty_rounded,
          ),
          _Choice(
            value: SupportNeed.relaxBody,
            title: l10n.needRelaxBody,
            icon: Icons.spa_outlined,
          ),
          _Choice(
            value: SupportNeed.maskNoise,
            title: l10n.needMaskNoise,
            icon: Icons.water_drop_outlined,
          ),
          _Choice(
            value: SupportNeed.nightAwake,
            title: l10n.needNightAwake,
            icon: Icons.nights_stay_outlined,
          ),
          _Choice(
            value: SupportNeed.gentleCompany,
            title: l10n.needGentleCompany,
            icon: Icons.nights_stay_outlined,
          ),
        ],
      ),
      1 => _ChoiceStep<SoundPreference>(
        title: l10n.onboardingSoundTitle,
        subtitle: l10n.onboardingSoundSubtitle,
        value: _soundPreference,
        compact: compact,
        onChanged: (value) => setState(() => _soundPreference = value),
        choices: [
          _Choice(
            value: SoundPreference.softVoice,
            title: l10n.soundSoftVoice,
            icon: Icons.graphic_eq_rounded,
          ),
          _Choice(
            value: SoundPreference.familiarMusic,
            title: l10n.soundFamiliarMusic,
            icon: Icons.music_note_rounded,
          ),
          _Choice(
            value: SoundPreference.nature,
            title: l10n.soundNature,
            icon: Icons.grain_rounded,
          ),
          _Choice(
            value: SoundPreference.minimal,
            title: l10n.soundMinimal,
            icon: Icons.volume_down_outlined,
          ),
        ],
      ),
      _ => _ChoiceStep<GuidancePreference>(
        title: l10n.onboardingGuidanceTitle,
        subtitle: l10n.onboardingGuidanceSubtitle,
        value: _guidancePreference,
        compact: compact,
        onChanged: (value) => setState(() => _guidancePreference = value),
        choices: [
          if (widget.hasGuidedRelaxation)
            _Choice(
              value: GuidancePreference.stepByStep,
              title: l10n.guidanceStepByStep,
              icon: Icons.route_outlined,
            ),
          _Choice(
            value: GuidancePreference.occasional,
            title: l10n.guidanceOccasional,
            icon: Icons.more_horiz_rounded,
          ),
          _Choice(
            value: GuidancePreference.ambientOnly,
            title: l10n.guidanceAmbientOnly,
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
