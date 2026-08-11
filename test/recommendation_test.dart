import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/data/content_catalog.dart';
import 'package:stillow/domain/stillow_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await ContentCatalog.loadAsset();
  });

  group('ContentCatalog.recommend', () {
    const profile = UserProfile(
      onboardingComplete: true,
      supportNeed: SupportNeed.quietMind,
      soundPreference: SoundPreference.softVoice,
      guidancePreference: GuidancePreference.occasional,
    );

    test('优先响应今晚的身体状态', () {
      final result = catalog.recommend(
        profile,
        ContentRegion.mainlandChina,
        NightState.tenseBody,
      );
      expect(result.tags, contains('relax_body'));
    });

    test('优先响应今晚的环境状态', () {
      final result = catalog.recommend(
        profile,
        ContentRegion.mainlandChina,
        NightState.noisyRoom,
      );
      expect(result.tags, contains('mask_noise'));
      expect(result.tags, contains('ambient'));
    });

    test('思绪活跃时返回无广告的低刺激内容', () {
      final result = catalog.recommend(
        profile,
        ContentRegion.mainlandChina,
        NightState.busyMind,
      );
      expect(result.tags, contains('quiet_mind'));
      expect(result.adFree, isTrue);
      expect(
        result.rightsStatus,
        anyOf(
          'publicDomain',
          'cc0',
          'ccBy',
          'ccBySa',
          'usGovernmentPublicDomain',
        ),
      );
    });

    test('不喜欢指令的人得到环境声', () {
      final result = catalog.recommend(
        const UserProfile(
          onboardingComplete: true,
          supportNeed: SupportNeed.quietMind,
          soundPreference: SoundPreference.minimal,
          guidancePreference: GuidancePreference.ambientOnly,
        ),
        ContentRegion.mainlandChina,
        NightState.busyMind,
      );
      expect(result.tags, contains('ambient'));
      expect(result.tags, isNot(contains('guided')));
    });

    test('中国大陆目录不包含 YouTube，国际目录不包含哔哩哔哩', () {
      final china = catalog.sessionsFor(ContentRegion.mainlandChina);
      final international = catalog.sessionsFor(ContentRegion.international);

      expect(china, isNotEmpty);
      expect(international, isNotEmpty);
      expect(china.any((item) => item.provider == 'youtube'), isFalse);
      expect(international.any((item) => item.provider == 'bilibili'), isFalse);
    });

    test('素材区域可跟随设备，也可由用户手动覆盖', () {
      expect(
        ContentRegionResolver.resolve(
          RegionPreference.automatic,
          ContentRegion.mainlandChina,
        ),
        ContentRegion.mainlandChina,
      );
      expect(
        ContentRegionResolver.resolve(
          RegionPreference.international,
          ContentRegion.mainlandChina,
        ),
        ContentRegion.international,
      );
      expect(
        ContentRegionResolver.resolve(
          RegionPreference.mainlandChina,
          ContentRegion.international,
        ),
        ContentRegion.mainlandChina,
      );
    });

    test('每条启用素材都有 HTTPS 播放和来源地址', () {
      for (final item in catalog.items.where((item) => item.enabled)) {
        expect(item.playbackUrl.scheme, 'https', reason: item.id);
        expect(item.sourcePage.scheme, 'https', reason: item.id);
        expect(item.tags, isNotEmpty, reason: item.id);
        expect(item.adFree, isTrue, reason: item.id);
        expect(item.isPlaybackEligible, isTrue, reason: item.id);
      }
    });

    test('目录不保留平台页面或含广告候选', () {
      expect(catalog.items.every((item) => item.adFree), isTrue);
      expect(catalog.items.every((item) => item.isPlaybackEligible), isTrue);
    });

    test('本地素材可读取，在线素材只使用 HTTPS 直连', () async {
      for (final item in catalog.items.where(
        (item) => item.isPlaybackEligible,
      )) {
        switch (item.playbackType) {
          case PlaybackType.assetAudio:
            expect(item.sha256, hasLength(64), reason: item.id);
            final bytes = await rootBundle.load(item.assetPath!);
            expect(
              bytes.lengthInBytes,
              greaterThan(10 * 1024),
              reason: item.id,
            );
          case PlaybackType.directAudio:
            expect(item.playbackUrl.scheme, 'https', reason: item.id);
            expect(item.assetPath, isNull, reason: item.id);
        }
      }
    });

    test('课程库有足够内容，并为在线课程提供离线兜底', () {
      final china = catalog.coursesFor(ContentRegion.mainlandChina);
      final international = catalog.coursesFor(ContentRegion.international);
      expect(china.length, greaterThanOrEqualTo(7));
      expect(international.length, 72);
      expect(
        catalog.items.where((item) => item.isPlaybackEligible).length,
        101,
      );
      expect(
        china.every((item) => item.playbackType == PlaybackType.assetAudio),
        isTrue,
      );
      for (final course in international.where(
        (item) => item.playbackType == PlaybackType.directAudio,
      )) {
        final fallback = catalog.offlineFallbackFor(
          course,
          ContentRegion.international,
        );
        expect(fallback, isNotNull, reason: course.id);
        expect(fallback!.kind, SessionKind.lecture, reason: course.id);
        expect(
          fallback.playbackType,
          PlaybackType.assetAudio,
          reason: course.id,
        );
      }
    });

    test('国内用户觉得还不困时，优先长篇中文课程', () {
      final result = catalog.recommend(
        const UserProfile(
          onboardingComplete: true,
          supportNeed: SupportNeed.notSleepy,
          soundPreference: SoundPreference.softVoice,
          guidancePreference: GuidancePreference.occasional,
        ),
        ContentRegion.mainlandChina,
        NightState.notSleepy,
      );

      expect(result.kind, SessionKind.lecture);
      expect(result.languageCode, 'zh');
      expect(result.durationSeconds, greaterThanOrEqualTo(30 * 60));
      expect(result.playbackType, PlaybackType.assetAudio);
      expect(result.tags, contains('not_sleepy'));
    });

    test('首次选择中的每种声音和引导偏好都有真实可播放内容', () {
      for (final region in ContentRegion.values) {
        final sessions = catalog.sessionsFor(region);
        expect(
          sessions.any((item) => item.tags.contains('soft_voice')),
          isTrue,
          reason: '$region 缺少轻声人声',
        );
        expect(
          sessions.any((item) => item.tags.contains('music')),
          isTrue,
          reason: '$region 缺少音乐',
        );
        expect(
          sessions.any((item) => item.tags.contains('nature')),
          isTrue,
          reason: '$region 缺少自然声',
        );
        expect(
          sessions.any((item) => item.tags.contains('minimal')),
          isTrue,
          reason: '$region 缺少极简声音',
        );
        expect(
          sessions.any((item) => item.tags.contains('guided')),
          isTrue,
          reason: '$region 缺少逐步引导',
        );
        expect(
          sessions.any((item) => item.tags.contains('ambient')),
          isTrue,
          reason: '$region 缺少纯环境声',
        );
      }
    });

    test('中文区同时提供音乐、中文朗读、中文科普和引导放松', () {
      final china = catalog.sessionsFor(ContentRegion.mainlandChina);
      expect(
        china.where((item) => item.kind == SessionKind.music).length,
        greaterThanOrEqualTo(5),
      );
      expect(
        china.where((item) => item.kind == SessionKind.narrative).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        china
            .where(
              (item) =>
                  item.kind == SessionKind.lecture &&
                  item.languageCode == 'zh' &&
                  (item.durationSeconds ?? 0) >= 30 * 60,
            )
            .length,
        greaterThanOrEqualTo(3),
      );
      expect(china.any((item) => item.kind == SessionKind.guidedVoice), isTrue);
    });

    test('夜醒推荐不会播放课程，也不会跳转平台', () {
      final result = catalog.recommendNightRescue(
        profile,
        ContentRegion.mainlandChina,
      );
      expect(result.kind, isNot(SessionKind.lecture));
      expect(result.tags, contains('night_awake'));
      expect(result.isPlaybackEligible, isTrue);
    });

    test('多次觉得舒服后，较低优先级的同类内容也会成为首选', () {
      final target = catalog.findById('music-soft-piano-loop')!;
      var learned = const UserProfile(
        onboardingComplete: true,
        supportNeed: SupportNeed.quietMind,
        soundPreference: SoundPreference.familiarMusic,
        guidancePreference: GuidancePreference.ambientOnly,
      );

      for (var index = 0; index < 4; index++) {
        learned = learned.learnFrom(target, SessionFeedback.comfortable);
      }

      final result = catalog.recommend(learned, ContentRegion.mainlandChina);
      expect(result.id, target.id);
      expect(learned.sessionAffinities[target.id], 12);
      expect(learned.tagAffinities['music'], 8);
    });

    test('不适合的反馈会跨越下一次使用继续降低同类和单条权重', () {
      final target = catalog.findById('music-first-light')!;
      final other = catalog.findById('narrative-cong-cong-zh')!;
      var learned = const UserProfile(
        onboardingComplete: true,
        supportNeed: SupportNeed.quietMind,
        soundPreference: SoundPreference.familiarMusic,
        guidancePreference: GuidancePreference.ambientOnly,
      );
      learned = learned.learnFrom(target, SessionFeedback.notForMe);
      learned = learned.learnFrom(target, SessionFeedback.notForMe);
      learned = learned
          .learnFrom(other, SessionFeedback.comfortable)
          .copyWith(
            lastSessionId: other.id,
            lastFeedback: SessionFeedback.comfortable,
          );

      final result = catalog.recommend(learned, ContentRegion.mainlandChina);
      expect(result.id, isNot(target.id));
      expect(learned.sessionAffinities[target.id], -8);
      expect(learned.tagAffinities['music'], -4);
    });
  });
}
