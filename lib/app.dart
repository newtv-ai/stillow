import 'package:flutter/material.dart';

import 'data/content_catalog.dart';
import 'data/preference_store.dart';
import 'domain/stillow_models.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'theme/stillow_theme.dart';

class StillowApp extends StatelessWidget {
  const StillowApp({
    super.key,
    required this.initialProfile,
    required this.preferenceStore,
    required this.catalog,
    required this.region,
  });

  final UserProfile initialProfile;
  final PreferenceStore preferenceStore;
  final ContentCatalog catalog;
  final ContentRegion region;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stillow',
      debugShowCheckedModeBanner: false,
      theme: StillowTheme.dark,
      home: StillowRoot(
        initialProfile: initialProfile,
        preferenceStore: preferenceStore,
        catalog: catalog,
        region: region,
      ),
    );
  }
}

class StillowRoot extends StatefulWidget {
  const StillowRoot({
    super.key,
    required this.initialProfile,
    required this.preferenceStore,
    required this.catalog,
    required this.region,
  });

  final UserProfile initialProfile;
  final PreferenceStore preferenceStore;
  final ContentCatalog catalog;
  final ContentRegion region;

  @override
  State<StillowRoot> createState() => _StillowRootState();
}

class _StillowRootState extends State<StillowRoot> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
  }

  Future<void> _completeOnboarding(UserProfile profile) async {
    await widget.preferenceStore.save(profile);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _recordSession(GuidedSession session) async {
    final updated = _profile.copyWith(
      lastSessionId: session.id,
      pendingFeedback: true,
      sessionCount: _profile.sessionCount + 1,
    );
    await widget.preferenceStore.save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _recordFeedback(SessionFeedback feedback) async {
    final updated = _profile.copyWith(
      pendingFeedback: false,
      lastFeedback: feedback,
      noHelpCount: feedback == SessionFeedback.comfortable
          ? 0
          : _profile.noHelpCount + 1,
    );
    await widget.preferenceStore.save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (!_profile.onboardingComplete) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    return HomeScreen(
      profile: _profile,
      catalog: widget.catalog,
      region: widget.region,
      onSessionStarted: _recordSession,
      onFeedback: _recordFeedback,
    );
  }
}
