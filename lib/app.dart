import 'package:flutter/material.dart';

import 'data/content_catalog.dart';
import 'data/preference_store.dart';
import 'data/sleep_history_store.dart';
import 'data/user_sound_store.dart';
import 'domain/stillow_models.dart';
import 'domain/sleep_history.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/privacy/data_privacy_screen.dart';
import 'l10n/l10n.dart';
import 'services/offline_audio_store.dart';
import 'services/sleep_health_gateway.dart';
import 'services/user_sound_picker.dart';
import 'theme/stillow_theme.dart';

class StillowApp extends StatefulWidget {
  const StillowApp({
    super.key,
    required this.initialProfile,
    required this.preferenceStore,
    required this.catalog,
    required this.region,
    required this.sleepHistoryStore,
    required this.sleepHealthGateway,
    this.initialUserSounds = const [],
    this.userSoundStore,
    this.userSoundPicker,
  });

  final UserProfile initialProfile;
  final PreferenceStore preferenceStore;
  final ContentCatalog catalog;
  final ContentRegion region;
  final SleepHistoryStore sleepHistoryStore;
  final SleepHealthGateway sleepHealthGateway;
  final List<UserSound> initialUserSounds;
  final UserSoundStore? userSoundStore;
  final UserSoundPicker? userSoundPicker;

  @override
  State<StillowApp> createState() => _StillowAppState();
}

class _StillowAppState extends State<StillowApp> {
  late AppLanguagePreference _languagePreference;

  @override
  void initState() {
    super.initState();
    _languagePreference = widget.initialProfile.appLanguagePreference;
  }

  Locale? get _locale => switch (_languagePreference) {
    AppLanguagePreference.system => null,
    AppLanguagePreference.simplifiedChinese => const Locale('zh'),
    AppLanguagePreference.english => const Locale('en'),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: StillowTheme.dark,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (locales, supportedLocales) {
        for (final locale in locales ?? const <Locale>[]) {
          if (locale.languageCode == 'zh') return const Locale('zh');
          if (locale.languageCode == 'en') return const Locale('en');
        }
        return const Locale('en');
      },
      routes: {
        '/privacy': (_) =>
            DataPrivacyScreen(historyStore: widget.sleepHistoryStore),
      },
      home: StillowRoot(
        initialProfile: widget.initialProfile,
        preferenceStore: widget.preferenceStore,
        catalog: widget.catalog,
        region: widget.region,
        sleepHistoryStore: widget.sleepHistoryStore,
        sleepHealthGateway: widget.sleepHealthGateway,
        initialUserSounds: widget.initialUserSounds,
        userSoundStore: widget.userSoundStore,
        userSoundPicker: widget.userSoundPicker,
        onAppLanguagePreferenceChanged: (preference) {
          if (_languagePreference == preference) return;
          setState(() => _languagePreference = preference);
        },
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
    required this.onAppLanguagePreferenceChanged,
    required this.initialUserSounds,
    this.userSoundStore,
    this.userSoundPicker,
  });

  final UserProfile initialProfile;
  final PreferenceStore preferenceStore;
  final ContentCatalog catalog;
  final ContentRegion region;
  final SleepHistoryStore sleepHistoryStore;
  final SleepHealthGateway sleepHealthGateway;
  final ValueChanged<AppLanguagePreference> onAppLanguagePreferenceChanged;
  final List<UserSound> initialUserSounds;
  final UserSoundStore? userSoundStore;
  final UserSoundPicker? userSoundPicker;

  @override
  State<StillowRoot> createState() => _StillowRootState();
}

class _StillowRootState extends State<StillowRoot> {
  late final PreferenceController _preferences;
  late final OfflineAudioStore _offlineAudioStore;
  late final UserSoundStore _userSoundStore;
  late final UserSoundPicker _userSoundPicker;
  late List<UserSound> _userSounds;

  @override
  void initState() {
    super.initState();
    _preferences = PreferenceController(
      store: widget.preferenceStore,
      initial: widget.initialProfile,
    );
    _offlineAudioStore = OfflineAudioStore();
    _userSoundStore = widget.userSoundStore ?? LocalUserSoundStore();
    _userSoundPicker = widget.userSoundPicker ?? PluginUserSoundPicker();
    _userSounds = [...widget.initialUserSounds];
  }

  UserProfile get _profile => _preferences.value;

  ContentRegion get _region =>
      ContentRegionResolver.resolve(_profile.regionPreference, widget.region);

  Future<void> _applyProfile(
    UserProfile Function(UserProfile current) update, {
    VoidCallback? onUpdated,
  }) async {
    final future = _preferences.apply(update);
    onUpdated?.call();
    if (!mounted) return;
    setState(() {});
    await future;
  }

  Future<void> _completeOnboarding(UserProfile profile) {
    return _applyProfile((_) => profile);
  }

  Future<void> _recordPlayback(PlaybackItem item, SleepUseContext context) {
    final session = item.guidedSession;
    if (session == null) return Future.value();
    return _applyProfile(
      (current) => current.copyWith(
        lastSessionId: session.id,
        lastUseContext: context,
        pendingFeedback: true,
      ),
    );
  }

  Future<void> _recordFeedback(SessionFeedback feedback) {
    return _applyProfile((current) {
      var updated = current.copyWith(
        pendingFeedback: false,
        lastFeedback: feedback,
        noHelpCount: feedback == SessionFeedback.comfortable
            ? 0
            : current.noHelpCount + 1,
      );
      final lastSession = widget.catalog.findById(current.lastSessionId);
      if (lastSession != null) {
        updated = updated.learnFrom(
          lastSession,
          feedback,
          context: current.lastUseContext,
        );
      }
      return updated;
    });
  }

  Future<void> _toggleFavorite(String sessionId) {
    return _applyProfile((current) {
      final favorites = Set<String>.from(current.favoriteSessionIds);
      if (!favorites.add(sessionId)) favorites.remove(sessionId);
      return current.copyWith(favoriteSessionIds: Set.unmodifiable(favorites));
    });
  }

  Future<void> _setRegionPreference(RegionPreference preference) {
    return _applyProfile(
      (current) => current.copyWith(regionPreference: preference),
    );
  }

  Future<void> _setAppLanguagePreference(AppLanguagePreference preference) {
    return _applyProfile(
      (current) => current.copyWith(appLanguagePreference: preference),
      onUpdated: () => widget.onAppLanguagePreferenceChanged(preference),
    );
  }

  Future<void> _setAudioLanguagePreference(AudioLanguagePreference preference) {
    return _applyProfile(
      (current) => current.copyWith(audioLanguagePreference: preference),
    );
  }

  Future<void> _setNightPreset(GuidedSession session) {
    return _applyProfile(
      (current) => current.copyWith(nightPresetSessionId: session.id),
    );
  }

  Future<List<UserSound>> _importUserSound(
    void Function(double progress) onProgress,
  ) async {
    final selections = await _userSoundPicker.pick();
    if (selections == null || selections.isEmpty) return const [];
    final sounds = await _userSoundStore.importAll(
      selections,
      onProgress: onProgress,
    );
    if (mounted) setState(() => _userSounds = [..._userSounds, ...sounds]);
    return sounds;
  }

  Future<void> _reorderUserSounds(List<UserSound> sounds) async {
    await _userSoundStore.reorder([for (final sound in sounds) sound.id]);
    if (mounted) setState(() => _userSounds = [...sounds]);
  }

  Future<UserSound> _updateUserSound(UserSound sound) async {
    final updated = await _userSoundStore.update(sound);
    if (mounted) {
      setState(() {
        _userSounds = [
          for (final entry in _userSounds)
            if (entry.id == updated.id) updated else entry,
        ];
      });
    }
    return updated;
  }

  Future<void> _deleteUserSound(String id) async {
    await _userSoundStore.delete(id);
    if (mounted) {
      setState(
        () => _userSounds = _userSounds
            .where((entry) => entry.id != id)
            .toList(growable: false),
      );
    }
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
    final localizedCatalog = widget.catalog.forExperience(
      interfaceLanguageCode: Localizations.localeOf(context).languageCode,
      audioLanguagePreference: _profile.audioLanguagePreference,
    );

    if (!_profile.onboardingComplete) {
      return OnboardingScreen(
        onComplete: _completeOnboarding,
        initialProfile: _profile,
        hasGuidedRelaxation: localizedCatalog.hasGuidedRelaxation,
      );
    }

    return HomeScreen(
      profile: _profile,
      catalog: localizedCatalog,
      region: _region,
      offlineAudioStore: _offlineAudioStore,
      userSounds: _userSounds,
      onPlaybackStarted: _recordPlayback,
      onFeedback: _recordFeedback,
      onFavoriteChanged: _toggleFavorite,
      onRegionPreferenceChanged: _setRegionPreference,
      onAppLanguagePreferenceChanged: _setAppLanguagePreference,
      onAudioLanguagePreferenceChanged: _setAudioLanguagePreference,
      onNightPresetChanged: _setNightPreset,
      onUserSoundImport: _importUserSound,
      onUserSoundImportCancelled: _userSoundStore.cancelImport,
      onUserSoundUsageRequested: _userSoundStore.usageBytes,
      onUserSoundChanged: _updateUserSound,
      onUserSoundDeleted: _deleteUserSound,
      onUserSoundsReordered: _reorderUserSounds,
      onProfileChanged: _completeOnboarding,
      onSessionFinished: _saveSleepSession,
      onMorningFeeling: _saveMorningFeeling,
      sleepHistoryStore: widget.sleepHistoryStore,
      sleepHealthGateway: widget.sleepHealthGateway,
    );
  }
}
