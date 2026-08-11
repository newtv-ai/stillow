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
            const SizedBox(height: 34),
            Text(
              '今晚更像是\n哪一种？',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              '不用仔细分析，选最接近的就好。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SoftChoiceCard(
                      title: '想法有点多',
                      icon: Icons.cloud_outlined,
                      onTap: () => _select(context, NightState.busyMind),
                    ),
                    const SizedBox(height: 12),
                    SoftChoiceCard(
                      title: '身体还没松下来',
                      icon: Icons.spa_outlined,
                      onTap: () => _select(context, NightState.tenseBody),
                    ),
                    const SizedBox(height: 12),
                    SoftChoiceCard(
                      title: '周围有点吵',
                      icon: Icons.water_drop_outlined,
                      onTap: () => _select(context, NightState.noisyRoom),
                    ),
                    const SizedBox(height: 12),
                    SoftChoiceCard(
                      title: '说不上来',
                      icon: Icons.more_horiz_rounded,
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
