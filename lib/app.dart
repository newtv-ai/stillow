import 'package:flutter/material.dart';

import 'data/content_catalog.dart';
import 'data/preference_store.dart';
import 'data/sleep_history_store.dart';
import 'domain/stillow_models.dart';
import 'domain/sleep_history.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/privacy/data_privacy_screen.dart';
import 'services/offline_audio_store.dart';
import 'services/sleep_health_gateway.dart';
import 'theme/stillow_theme.dart';

class StillowApp extends StatelessWidget {
  const StillowApp({
    super.key,
    required this.initialProfile,
    required this.preferenceStore,
    required this.catalog,
    required this.region,
    required this.sleepHistoryStore,
    required this.sleepHealthGateway,
  });

  final UserProfile initialProfile;
  final PreferenceStore preferenceStore;
  final ContentCatalog catalog;
  final ContentRegion region;
  final SleepHistoryStore sleepHistoryStore;
  final SleepHealthGateway sleepHealthGateway;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stillow',
      debugShowCheckedModeBanner: false,
      theme: StillowTheme.dark,
      routes: {
        '/privacy': (_) => DataPrivacyScreen(historyStore: sleepHistoryStore),
      },
      home: StillowRoot(
        initialProfile: initialProfile,
        preferenceStore: preferenceStore,
        catalog: catalog,
        region: region,
        sleepHistoryStore: sleepHistoryStore,
        sleepHealthGateway: sleepHealthGateway,
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
    required this.sleepHistoryStore,
    required this.sleepHealthGateway,
  });

  final UserProfile initialProfile;
  final PreferenceStore preferenceStore;
  final ContentCatalog catalog;
  final ContentRegion region;
  final SleepHistoryStore sleepHistoryStore;
  final SleepHealthGateway sleepHealthGateway;

  @override
  State<StillowRoot> createState() => _StillowRootState();
}

class _StillowRootState extends State<StillowRoot> {
  late UserProfile _profile;
  late final OfflineAudioStore _offlineAudioStore;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _offlineAudioStore = OfflineAudioStore();
  }

  ContentRegion get _region =>
      ContentRegionResolver.resolve(_profile.regionPreference, widget.region);

  Future<void> _completeOnboarding(UserProfile profile) async {
    await widget.preferenceStore.save(profile);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _recordSession(
    GuidedSession session,
    SleepUseContext context,
  ) async {
    final updated = _profile.copyWith(
      lastSessionId: session.id,
      lastUseContext: context,
      pendingFeedback: true,
    );
    await widget.preferenceStore.save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _recordFeedback(SessionFeedback feedback) async {
    var updated = _profile.copyWith(
      pendingFeedback: false,
      lastFeedback: feedback,
      noHelpCount: feedback == SessionFeedback.comfortable
          ? 0
          : _profile.noHelpCount + 1,
    );
    final lastSession = widget.catalog.findById(_profile.lastSessionId);
    if (lastSession != null) {
      updated = updated.learnFrom(
        lastSession,
        feedback,
        context: _profile.lastUseContext,
      );
    }
    await widget.preferenceStore.save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _toggleFavorite(String sessionId) async {
    final favorites = Set<String>.from(_profile.favoriteSessionIds);
    if (!favorites.add(sessionId)) favorites.remove(sessionId);
    final updated = _profile.copyWith(
      favoriteSessionIds: Set.unmodifiable(favorites),
    );
    await widget.preferenceStore.save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _setRegionPreference(RegionPreference preference) async {
    final updated = _profile.copyWith(regionPreference: preference);
    await widget.preferenceStore.save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _setNightPreset(GuidedSession session) async {
    final updated = _profile.copyWith(nightPresetSessionId: session.id);
    await widget.preferenceStore.save(updated);
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  Future<void> _saveSleepSession(AppSleepSessionRecord record) =>
      widget.sleepHistoryStore.saveAppSession(record);

  Future<void> _saveMorningFeeling(MorningFeeling feeling) {
    final now = DateTime.now();
    return widget.sleepHistoryStore.saveMorningCheckIn(
      MorningCheckIn(
        id: 'morning-${now.microsecondsSinceEpoch}',
        recordedAt: now,
        feeling: feeling,
      ),
    );
  }

  @override
  void dispose() {
    _offlineAudioStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_profile.onboardingComplete) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    return HomeScreen(
      profile: _profile,
      catalog: widget.catalog,
      region: _region,
      offlineAudioStore: _offlineAudioStore,
      onSessionStarted: _recordSession,
      onFeedback: _recordFeedback,
      onFavoriteChanged: _toggleFavorite,
      onRegionPreferenceChanged: _setRegionPreference,
      onNightPresetChanged: _setNightPreset,
      onProfileChanged: _completeOnboarding,
      onSessionFinished: _saveSleepSession,
      onMorningFeeling: _saveMorningFeeling,
      sleepHistoryStore: widget.sleepHistoryStore,
      sleepHealthGateway: widget.sleepHealthGateway,
    );
  }
}
