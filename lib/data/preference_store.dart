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
  Future<UserProfile> load() async {
    try {
      return _profileFromJson(await _file.read());
    } catch (_) {
      return const UserProfile();
    }
  }

  @override
  Future<void> save(UserProfile profile) =>
      _file.write(_profileToJson(profile));
}

/// Keeps the in-memory profile authoritative and serializes disk writes.
///
/// Callers must [apply] from the latest [value]; overlapping UI actions then
/// compose instead of letting a later full-snapshot save erase an earlier one.
final class PreferenceController {
  PreferenceController({
    required PreferenceStore store,
    required UserProfile initial,
  }) : _store = store,
       value = initial;

  final PreferenceStore _store;
  UserProfile value;
  Future<void> _pending = Future.value();

  Future<void> apply(UserProfile Function(UserProfile current) update) {
    value = update(value);
    final snapshot = value;
    final operation = _pending.then((_) => _store.save(snapshot));
    _pending = operation.catchError((_) {});
    return operation;
  }
}

Map<String, Object?> _profileToJson(UserProfile profile) => {
  'version': 5,
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
  'appLanguagePreference': profile.appLanguagePreference.name,
  'audioLanguagePreference': profile.audioLanguagePreference.name,
  'nightPresetSessionId': profile.nightPresetSessionId,
};

UserProfile _profileFromJson(Object? value) {
  if (value is! Map) return const UserProfile();
  final json = Map<String, dynamic>.from(value);
  return UserProfile(
    onboardingComplete: json['onboardingComplete'] == true,
    supportNeed: _enumByName(
      SupportNeed.values,
      _asString(json['supportNeed']),
    ),
    soundPreference: _enumByName(
      SoundPreference.values,
      _asString(json['soundPreference']),
    ),
    guidancePreference: _enumByName(
      GuidancePreference.values,
      _asString(json['guidancePreference']),
    ),
    lastSessionId: _asString(json['lastSessionId']),
    lastUseContext:
        _enumByName(
          SleepUseContext.values,
          _asString(json['lastUseContext']),
        ) ??
        SleepUseContext.bedtime,
    pendingFeedback: json['pendingFeedback'] == true,
    lastFeedback: _enumByName(
      SessionFeedback.values,
      _asString(json['lastFeedback']),
    ),
    noHelpCount: (_asNum(json['noHelpCount'])?.toInt().clamp(0, 1000)) ?? 0,
    tagAffinities: _decodeAffinities(json['tagAffinities']),
    sessionAffinities: _decodeAffinities(json['sessionAffinities']),
    favoriteSessionIds: Set.unmodifiable(
      _asStringList(json['favoriteSessionIds']),
    ),
    regionPreference:
        _enumByName(
          RegionPreference.values,
          _asString(json['regionPreference']),
        ) ??
        RegionPreference.automatic,
    appLanguagePreference:
        _enumByName(
          AppLanguagePreference.values,
          _asString(json['appLanguagePreference']),
        ) ??
        AppLanguagePreference.system,
    audioLanguagePreference:
        _enumByName(
          AudioLanguagePreference.values,
          _asString(json['audioLanguagePreference']),
        ) ??
        AudioLanguagePreference.automatic,
    nightPresetSessionId: _asString(json['nightPresetSessionId']),
  );
}

String? _asString(Object? value) => value is String ? value : null;

num? _asNum(Object? value) => value is num ? value : null;

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
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
