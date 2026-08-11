import 'package:flutter/material.dart';

import '../../data/content_catalog.dart';
import '../../domain/stillow_models.dart';
import '../../widgets/soft_ui.dart';

class TonightStateScreen extends StatelessWidget {
  const TonightStateScreen({
    super.key,
    required this.profile,
    required this.catalog,
    required this.region,
  });

  final UserProfile profile;
  final ContentCatalog catalog;
  final ContentRegion region;

  void _select(BuildContext context, NightState? state) {
    Navigator.of(context).pop(catalog.recommend(profile, region, state));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StillowBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuietIconButton(
              icon: Icons.close_rounded,
              tooltip: '关闭',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 20),
            Text(
              '今晚更像是\n哪一种？',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '不用仔细分析，选最接近的就好。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SoftChoiceCard(
                      title: '想法有点多',
                      icon: Icons.cloud_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.busyMind),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: '没想什么，只是还不困',
                      icon: Icons.visibility_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.notSleepy),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: '有点着急，越想睡越清醒',
                      icon: Icons.hourglass_empty_rounded,
                      dense: true,
                      onTap: () => _select(context, NightState.sleepPressure),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: '身体还没松下来',
                      icon: Icons.spa_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.tenseBody),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: '周围有点吵',
                      icon: Icons.water_drop_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.noisyRoom),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: '是夜里醒来后',
                      icon: Icons.nights_stay_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.nightAwake),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: '说不上来',
                      icon: Icons.more_horiz_rounded,
                      dense: true,
                      onTap: () => _select(context, NightState.unsure),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () => _select(context, null),
              child: const Text('跳过，继续熟悉的方式'),
            ),
          ],
        ),
      ),
    );
  }
}
