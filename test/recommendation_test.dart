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
      expect(result.rightsStatus, anyOf('publicDomain', 'cc0'));
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

    test('每条启用素材都有 HTTPS 播放和来源地址', () {
      for (final item in catalog.items.where((item) => item.enabled)) {
        expect(item.playbackUrl.scheme, 'https', reason: item.id);
        expect(item.sourcePage.scheme, 'https', reason: item.id);
        expect(item.tags, isNotEmpty, reason: item.id);
        expect(item.adFree, isTrue, reason: item.id);
        expect(item.isPlaybackEligible, isTrue, reason: item.id);
      }
    });

    test('平台候选不会进入播放池', () {
      final platformCandidates = catalog.items.where(
        (item) => item.playbackType == PlaybackType.platformPage,
      );
      expect(platformCandidates, isNotEmpty);
      expect(platformCandidates.every((item) => !item.enabled), isTrue);
      expect(platformCandidates.every((item) => !item.adFree), isTrue);
      expect(
        platformCandidates.every((item) => !item.isPlaybackEligible),
        isTrue,
      );
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
          case PlaybackType.platformPage:
            fail('平台页面不应进入可播放池：${item.id}');
        }
      }
    });

    test('课程库有足够内容，并为在线课程提供离线兜底', () {
      final china = catalog.coursesFor(ContentRegion.mainlandChina);
      final international = catalog.coursesFor(ContentRegion.international);
      expect(china.length, greaterThanOrEqualTo(3));
      expect(international.length, 71);
      expect(catalog.items.where((item) => item.isPlaybackEligible).length, 75);
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

    test('夜醒推荐不会播放课程，也不会跳转平台', () {
      final result = catalog.recommendNightRescue(
        profile,
        ContentRegion.mainlandChina,
      );
      expect(result.kind, isNot(SessionKind.lecture));
      expect(result.tags, contains('night_awake'));
      expect(result.isPlaybackEligible, isTrue);
    });
  });
}
