import 'package:flutter/material.dart';

import '../../data/content_catalog.dart';
import '../../domain/stillow_models.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';
import '../night/night_rescue_screen.dart';
import '../morning/morning_review_screen.dart';
import '../player/player_screen.dart';
import '../session/session_library_screen.dart';
import '../session/tonight_state_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.catalog,
    required this.region,
    required this.onSessionStarted,
    required this.onFeedback,
  });

  final UserProfile profile;
  final ContentCatalog catalog;
  final ContentRegion region;
  final Future<void> Function(GuidedSession session) onSessionStarted;
  final Future<void> Function(SessionFeedback feedback) onFeedback;

  Future<void> _openPlayer(BuildContext context, GuidedSession session) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          session: session,
          fallbackSession: catalog.offlineFallbackFor(session, region),
          onSessionStarted: onSessionStarted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = catalog.recommend(profile, region);

    return Scaffold(
      body: StillowBackdrop(
        padding: EdgeInsets.zero,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 38),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      const StillowWordmark(),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showAbout(context),
                        tooltip: '关于 Stillow',
                        icon: const Icon(Icons.more_horiz_rounded),
                        color: StillowColors.linenMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),
                  Text(
                    '今晚不用完成\n任何任务。',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '只选一种此刻觉得舒服的陪伴。',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: StillowColors.linenMuted,
                    ),
                  ),
                  const SizedBox(height: 34),
                  _RecommendationCard(
                    session: recommendation,
                    onTap: () => _openPlayer(context, recommendation),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final session = await Navigator.of(context)
                          .push<GuidedSession>(
                            MaterialPageRoute<GuidedSession>(
                              builder: (_) => TonightStateScreen(
                                profile: profile,
                                catalog: catalog,
                                region: region,
                              ),
                            ),
                          );
                      if (session != null && context.mounted) {
                        await _openPlayer(context, session);
                      }
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('今晚感觉有点不同'),
                    style: FilledButton.styleFrom(
                      backgroundColor: StillowColors.surfaceRaised,
                      foregroundColor: StillowColors.linen,
                    ),
                  ),
                  if (profile.pendingFeedback) ...[
                    const SizedBox(height: 28),
                    _FeedbackCard(onFeedback: onFeedback),
                  ],
                  if (profile.noHelpCount >= 4) ...[
                    const SizedBox(height: 14),
                    _GentleSupportCard(
                      showProfessional: profile.noHelpCount >= 10,
                    ),
                  ],
                  const SizedBox(height: 36),
                  Text('想换一种方式', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  _QuietAction(
                    icon: Icons.grid_view_rounded,
                    title: '看看其他陪伴',
                    subtitle: '人声引导、雨声、海浪和低沉噪音',
                    onTap: () async {
                      final session = await Navigator.of(context)
                          .push<GuidedSession>(
                            MaterialPageRoute<GuidedSession>(
                              builder: (_) => SessionLibraryScreen(
                                sessions: catalog.sessionsFor(region),
                              ),
                            ),
                          );
                      if (session != null && context.mounted) {
                        await _openPlayer(context, session);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuietAction(
                    icon: Icons.school_outlined,
                    title: '听一段不必学会的课',
                    subtitle: '地质、气象与物理旧版讲读，放在远处听就好',
                    onTap: () async {
                      final session = await Navigator.of(context)
                          .push<GuidedSession>(
                            MaterialPageRoute<GuidedSession>(
                              builder: (_) => SessionLibraryScreen(
                                sessions: catalog.coursesFor(region),
                                title: '听一段\n不必学会的课',
                                subtitle: '内容平直、没有测验。听不懂也完全没关系。',
                              ),
                            ),
                          );
                      if (session != null && context.mounted) {
                        await _openPlayer(context, session);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuietAction(
                    icon: Icons.nights_stay_outlined,
                    title: '夜里醒来时',
                    subtitle: '不看时间，一键开始预设陪伴',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NightRescueScreen(
                          profile: profile,
                          catalog: catalog,
                          region: region,
                          onSessionStarted: onSessionStarted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuietAction(
                    icon: Icons.wb_twilight_outlined,
                    title: '醒来以后',
                    subtitle: '看看此刻的恢复感，或者轻松聊聊昨晚的梦',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MorningReviewScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  Center(
                    child: Text(
                      '想用时再来。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StillowWordmark(),
                const SizedBox(height: 20),
                Text(
                  '不催你睡，只陪你慢慢安静。',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Stillow 当前是体验原型，不用于诊断或治疗睡眠疾病。'
                  '如果经常憋醒、呼吸暂停，或白天困倦已经影响驾驶安全，'
                  '更适合先找专业人士确认。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.session, required this.onTap});

  final GuidedSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF31443E), Color(0xFF202D2A)],
            ),
            border: Border.all(color: const Color(0xFF445B53)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: StillowColors.background.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(session.icon, color: StillowColors.moon),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 42,
                    color: StillowColors.moon,
                  ),
                ],
              ),
              const SizedBox(height: 38),
              Text('今晚先试试', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 5),
              Text(
                session.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                session.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietAction extends StatelessWidget {
  const _QuietAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StillowColors.surface.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: StillowColors.sage),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: StillowColors.linenMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GentleSupportCard extends StatelessWidget {
  const _GentleSupportCard({required this.showProfessional});

  final bool showProfessional;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StillowColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: StillowColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showProfessional ? '声音可能不是全部答案' : '换条完全不同的路试试',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            showProfessional
                ? '如果已经多次尝试仍没帮助，可以选择了解什么时候值得找专业人士聊聊。'
                : '看来最近试过的声音没有明显帮助。可以从人声换到自然声，或反过来；不用勉强坚持。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (showProfessional) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _showProfessionalHelp(context),
              child: const Text('我想了解一下'),
            ),
          ],
        ],
      ),
    );
  }

  void _showProfessionalHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '这不是考试，也不会给你贴标签。',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'App 没帮上忙本身不能证明是慢性失眠。如果入睡或夜醒困难持续较久、经常发生，并已经影响白天状态，找医生或睡眠专业人士聊聊会更合适。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '如果经常憋醒、喘醒、被观察到呼吸暂停，或白天困倦已经影响驾驶安全，不用继续等 App 调整，尽早就医确认。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '正式睡眠量表会在完成中文版授权与专业审核后提供；当前版本不会用自制问卷替代诊断。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard({required this.onFeedback});

  final Future<void> Function(SessionFeedback feedback) onFeedback;

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  bool _saving = false;

  Future<void> _choose(SessionFeedback feedback) async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.onFeedback(feedback);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StillowColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: StillowColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('有空的时候，告诉我们', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('上次那段陪伴感觉怎么样？', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeedbackChip(
                label: '挺舒服的',
                onTap: _saving
                    ? null
                    : () => _choose(SessionFeedback.comfortable),
              ),
              _FeedbackChip(
                label: '没什么区别',
                onTap: _saving
                    ? null
                    : () => _choose(SessionFeedback.noDifference),
              ),
              _FeedbackChip(
                label: '不太适合',
                onTap: _saving ? null : () => _choose(SessionFeedback.notForMe),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      backgroundColor: StillowColors.surfaceRaised,
      side: const BorderSide(color: StillowColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    );
  }
}
