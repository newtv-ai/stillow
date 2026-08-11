import 'package:flutter/material.dart';

import '../../data/content_catalog.dart';
import '../../domain/stillow_models.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';
import '../player/player_screen.dart';

class NightRescueScreen extends StatelessWidget {
  const NightRescueScreen({
    super.key,
    required this.profile,
    required this.catalog,
    required this.region,
    required this.onSessionStarted,
  });

  final UserProfile profile;
  final ContentCatalog catalog;
  final ContentRegion region;
  final Future<void> Function(GuidedSession session) onSessionStarted;

  @override
  Widget build(BuildContext context) {
    final session = catalog.recommendNightRescue(profile, region);

    return Scaffold(
      body: StillowBackdrop(
        showGlow: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: QuietIconButton(
                icon: Icons.close_rounded,
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Spacer(),
            AmbientOrb(
              active: true,
              size: 235,
              icon: Icons.nights_stay_outlined,
            ),
            const SizedBox(height: 44),
            Text('不用看时间。', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              '也不用现在弄清为什么醒来。',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: StillowColors.linenMuted),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => PlayerScreen(
                    session: session,
                    onSessionStarted: onSessionStarted,
                    nightMode: true,
                    autoStart: true,
                    fallbackSession: catalog.offlineFallbackFor(
                      session,
                      region,
                    ),
                  ),
                ),
              ),
              child: const Text('帮我慢慢安静下来'),
            ),
            const SizedBox(height: 14),
            Text(
              '如果有疼痛、呼吸不适或需要如厕，请先照顾身体。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
