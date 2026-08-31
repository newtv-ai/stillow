import 'package:flutter/material.dart';

import '../../data/content_catalog.dart';
import '../../domain/stillow_models.dart';
import '../../l10n/l10n.dart';
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
    final l10n = context.l10n;
    return Scaffold(
      body: StillowBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuietIconButton(
              icon: Icons.close_rounded,
              tooltip: l10n.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.tonightStateTitle,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tonightStateSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SoftChoiceCard(
                      title: l10n.stateBusyMind,
                      icon: Icons.cloud_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.busyMind),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: l10n.stateNotSleepy,
                      icon: Icons.visibility_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.notSleepy),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: l10n.stateSleepPressure,
                      icon: Icons.hourglass_empty_rounded,
                      dense: true,
                      onTap: () => _select(context, NightState.sleepPressure),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: l10n.stateTenseBody,
                      icon: Icons.spa_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.tenseBody),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: l10n.stateNoisyRoom,
                      icon: Icons.water_drop_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.noisyRoom),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: l10n.stateNightAwake,
                      icon: Icons.nights_stay_outlined,
                      dense: true,
                      onTap: () => _select(context, NightState.nightAwake),
                    ),
                    const SizedBox(height: 8),
                    SoftChoiceCard(
                      title: l10n.stateUnsure,
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
              child: Text(l10n.tonightStateSkip),
            ),
          ],
        ),
      ),
    );
  }
}
