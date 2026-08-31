import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/data/preference_store.dart';
import 'package:stillow/domain/stillow_models.dart';

import 'support/fakes.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('stillow-preferences-');
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('个性化权重会随不可备份的本地偏好一起保存和恢复', () async {
    final store = LocalPreferenceStore(
      directoryProvider: () async => directory,
    );
    const profile = UserProfile(
      onboardingComplete: true,
      supportNeed: SupportNeed.notSleepy,
      lastUseContext: SleepUseContext.nightAwake,
      tagAffinities: {'music': 6, 'ambient': 4},
      sessionAffinities: {'music-first-light': 9},
      favoriteSessionIds: {'music-first-light', 'intl-gentle-rain'},
      regionPreference: RegionPreference.international,
      appLanguagePreference: AppLanguagePreference.english,
      audioLanguagePreference: AudioLanguagePreference.english,
      nightPresetSessionId: 'music-first-light',
    );

    await store.save(profile);
    final restored = await store.load();

    expect(restored.supportNeed, SupportNeed.notSleepy);
    expect(restored.lastUseContext, SleepUseContext.nightAwake);
    expect(restored.tagAffinities, profile.tagAffinities);
    expect(restored.sessionAffinities, profile.sessionAffinities);
    expect(restored.favoriteSessionIds, profile.favoriteSessionIds);
    expect(restored.regionPreference, profile.regionPreference);
    expect(restored.appLanguagePreference, profile.appLanguagePreference);
    expect(restored.audioLanguagePreference, profile.audioLanguagePreference);
    expect(restored.nightPresetSessionId, profile.nightPresetSessionId);
  });

  test('旧版个人声音默认字段会被忽略并在下次保存时移除', () async {
    final preferences = File(
      '${directory.path}${Platform.pathSeparator}preferences.json',
    );
    await preferences.writeAsString(
      '{"version":4,"onboardingComplete":true,'
      '"nightPresetSessionId":"built-in",'
      '"tonightDefaultUserSoundId":"tonight",'
      '"nightPresetUserSoundId":"night"}',
    );

    final store = LocalPreferenceStore(
      directoryProvider: () async => directory,
    );
    final restored = await store.load();
    await store.save(restored);
    final saved = await preferences.readAsString();

    expect(restored.nightPresetSessionId, 'built-in');
    expect(saved, isNot(contains('tonightDefaultUserSoundId')));
    expect(saved, isNot(contains('nightPresetUserSoundId')));
  });

  test('损坏的本地偏好不会阻止应用启动', () async {
    await File(
      '${directory.path}${Platform.pathSeparator}preferences.json',
    ).writeAsString('{not-json');

    final restored = await LocalPreferenceStore(
      directoryProvider: () async => directory,
    ).load();

    expect(restored.onboardingComplete, isFalse);
    expect(restored.tagAffinities, isEmpty);
  });

  test('合法 JSON 里的错误字段类型不会阻止启动', () async {
    await File(
      '${directory.path}${Platform.pathSeparator}preferences.json',
    ).writeAsString(
      '{"supportNeed":7,"favoriteSessionIds":"broken","noHelpCount":"x","lastSessionId":1}',
    );

    final restored = await LocalPreferenceStore(
      directoryProvider: () async => directory,
    ).load();

    expect(restored.onboardingComplete, isFalse);
    expect(restored.supportNeed, isNull);
    expect(restored.favoriteSessionIds, isEmpty);
    expect(restored.noHelpCount, 0);
    expect(restored.lastSessionId, isNull);
  });

  test('重叠的偏好更新会基于最新内存快照串行写入', () async {
    final inner = MemoryPreferenceStore();
    final store = _SlowPreferenceStore(inner);
    final controller = PreferenceController(
      store: store,
      initial: const UserProfile(),
    );

    final first = controller.apply(
      (current) => current.copyWith(favoriteSessionIds: const {'a'}),
    );
    final second = controller.apply((current) {
      return current.copyWith(
        favoriteSessionIds: {...current.favoriteSessionIds, 'b'},
        appLanguagePreference: AppLanguagePreference.english,
      );
    });
    await Future.wait([first, second]);

    expect(controller.value.favoriteSessionIds, {'a', 'b'});
    expect(inner.profile.favoriteSessionIds, {'a', 'b'});
    expect(inner.profile.appLanguagePreference, AppLanguagePreference.english);
  });
}

class _SlowPreferenceStore implements PreferenceStore {
  _SlowPreferenceStore(this._inner);

  final MemoryPreferenceStore _inner;

  @override
  Future<UserProfile> load() => _inner.load();

  @override
  Future<void> save(UserProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await _inner.save(profile);
  }
}
