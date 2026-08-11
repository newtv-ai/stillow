import 'package:shared_preferences/shared_preferences.dart';

import '../domain/stillow_models.dart';

abstract interface class PreferenceStore {
  Future<UserProfile> load();
  Future<void> save(UserProfile profile);
}

class SharedPreferencesStore implements PreferenceStore {
  static const _onboardingKey = 'onboarding_complete';
  static const _supportNeedKey = 'support_need';
  static const _soundPreferenceKey = 'sound_preference';
  static const _guidancePreferenceKey = 'guidance_preference';
  static const _lastSessionKey = 'last_session';
  static const _pendingFeedbackKey = 'pending_feedback';
  static const _lastFeedbackKey = 'last_feedback';
  static const _sessionCountKey = 'session_count';
  static const _noHelpCountKey = 'no_help_count';

  @override
  Future<UserProfile> load() async {
    final preferences = await SharedPreferences.getInstance();

    return UserProfile(
      onboardingComplete: preferences.getBool(_onboardingKey) ?? false,
      supportNeed: _enumByName(
        SupportNeed.values,
        preferences.getString(_supportNeedKey),
      ),
      soundPreference: _enumByName(
        SoundPreference.values,
        preferences.getString(_soundPreferenceKey),
      ),
      guidancePreference: _enumByName(
        GuidancePreference.values,
        preferences.getString(_guidancePreferenceKey),
      ),
      lastSessionId: preferences.getString(_lastSessionKey),
      pendingFeedback: preferences.getBool(_pendingFeedbackKey) ?? false,
      lastFeedback: _enumByName(
        SessionFeedback.values,
        preferences.getString(_lastFeedbackKey),
      ),
      sessionCount: preferences.getInt(_sessionCountKey) ?? 0,
      noHelpCount: preferences.getInt(_noHelpCountKey) ?? 0,
    );
  }

  @override
  Future<void> save(UserProfile profile) async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.setBool(_onboardingKey, profile.onboardingComplete),
      _setOptional(preferences, _supportNeedKey, profile.supportNeed?.name),
      _setOptional(
        preferences,
        _soundPreferenceKey,
        profile.soundPreference?.name,
      ),
      _setOptional(
        preferences,
        _guidancePreferenceKey,
        profile.guidancePreference?.name,
      ),
      _setOptional(preferences, _lastSessionKey, profile.lastSessionId),
      preferences.setBool(_pendingFeedbackKey, profile.pendingFeedback),
      _setOptional(preferences, _lastFeedbackKey, profile.lastFeedback?.name),
      preferences.setInt(_sessionCountKey, profile.sessionCount),
      preferences.setInt(_noHelpCountKey, profile.noHelpCount),
    ]);
  }

  static T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  static Future<bool> _setOptional(
    SharedPreferences preferences,
    String key,
    String? value,
  ) {
    if (value == null) return preferences.remove(key);
    return preferences.setString(key, value);
  }
}

class MemoryPreferenceStore implements PreferenceStore {
  MemoryPreferenceStore([this.profile = const UserProfile()]);

  UserProfile profile;

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile profile) async {
    this.profile = profile;
  }
}
