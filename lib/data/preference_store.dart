import '../domain/stillow_models.dart';
import '../services/private_local_storage.dart';

abstract interface class PreferenceStore {
  Future<UserProfile> load();

  Future<void> save(UserProfile profile);
}

class LocalPreferenceStore implements PreferenceStore {
  LocalPreferenceStore({PrivateDirectoryProvider? directoryProvider})
    : _file = PrivateJsonFile(
        'preferences.json',
        directoryProvider: directoryProvider,
      );

  final PrivateJsonFile _file;

  @override
  Future<UserProfile> load() async => _profileFromJson(await _file.read());

  @override
  Future<void> save(UserProfile profile) =>
      _file.write(_profileToJson(profile));
}

Map<String, Object?> _profileToJson(UserProfile profile) => {
  'version': 2,
  'onboardingComplete': profile.onboardingComplete,
  'supportNeed': profile.supportNeed?.name,
  'soundPreference': profile.soundPreference?.name,
  'guidancePreference': profile.guidancePreference?.name,
  'lastSessionId': profile.lastSessionId,
  'lastUseContext': profile.lastUseContext.name,
  'pendingFeedback': profile.pendingFeedback,
  'lastFeedback': profile.lastFeedback?.name,
  'noHelpCount': profile.noHelpCount,
  'tagAffinities': profile.tagAffinities,
  'sessionAffinities': profile.sessionAffinities,
  'favoriteSessionIds': profile.favoriteSessionIds.toList()..sort(),
  'regionPreference': profile.regionPreference.name,
  'nightPresetSessionId': profile.nightPresetSessionId,
};

UserProfile _profileFromJson(Object? value) {
  if (value is! Map) return const UserProfile();
  final json = Map<String, dynamic>.from(value);
  return UserProfile(
    onboardingComplete: json['onboardingComplete'] == true,
    supportNeed: _enumByName(
      SupportNeed.values,
      json['supportNeed'] as String?,
    ),
    soundPreference: _enumByName(
      SoundPreference.values,
      json['soundPreference'] as String?,
    ),
    guidancePreference: _enumByName(
      GuidancePreference.values,
      json['guidancePreference'] as String?,
    ),
    lastSessionId: json['lastSessionId'] as String?,
    lastUseContext:
        _enumByName(
          SleepUseContext.values,
          json['lastUseContext'] as String?,
        ) ??
        SleepUseContext.bedtime,
    pendingFeedback: json['pendingFeedback'] == true,
    lastFeedback: _enumByName(
      SessionFeedback.values,
      json['lastFeedback'] as String?,
    ),
    noHelpCount: (json['noHelpCount'] as num?)?.toInt().clamp(0, 1000) ?? 0,
    tagAffinities: _decodeAffinities(json['tagAffinities']),
    sessionAffinities: _decodeAffinities(json['sessionAffinities']),
    favoriteSessionIds: Set.unmodifiable(
      (json['favoriteSessionIds'] as List? ?? const []).whereType<String>(),
    ),
    regionPreference:
        _enumByName(
          RegionPreference.values,
          json['regionPreference'] as String?,
        ) ??
        RegionPreference.automatic,
    nightPresetSessionId: json['nightPresetSessionId'] as String?,
  );
}

Map<String, int> _decodeAffinities(Object? value) {
  if (value is! Map) return const {};
  final result = <String, int>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! num) continue;
    final score = (entry.value as num).toInt().clamp(-100, 100);
    if (score != 0) result[entry.key as String] = score;
  }
  return Map.unmodifiable(result);
}

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
