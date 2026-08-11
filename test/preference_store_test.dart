import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/data/preference_store.dart';
import 'package:stillow/domain/stillow_models.dart';

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
    expect(restored.nightPresetSessionId, profile.nightPresetSessionId);
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
}
