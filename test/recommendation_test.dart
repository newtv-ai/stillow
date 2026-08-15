import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/data/content_catalog.dart';
import 'package:stillow/domain/stillow_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentCatalog catalog;
  late ContentCatalog reviewCatalog;

  setUpAll(() async {
    catalog = await ContentCatalog.loadAsset();
    final catalogText = await rootBundle.loadString(
      'assets/content/audio_catalog.json',
    );
    final candidateText = await File(
      'assets/content/audio_candidates.json',
    ).readAsString();
    reviewCatalog = ContentCatalog.fromJsonString(
      catalogText,
      candidateJsonText: candidateText,
    );
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
      expect(result.tags, contains('role_trial_aligned_music'));
    });

    test('优先响应今晚的环境状态，并只把环境声当作遮噪', () {
      final result = catalog.recommend(
        profile,
        ContentRegion.mainlandChina,
        NightState.noisyRoom,
      );
      expect(result.tags, contains('mask_noise'));
      expect(result.tags, contains('ambient'));
      expect(result.tags, contains('role_masking_only'));
    });

    test('思绪活跃时优先试验范式对齐的低刺激音乐', () {
      final result = catalog.recommend(
        profile,
        ContentRegion.mainlandChina,
        NightState.busyMind,
      );
      expect(result.tags, contains('quiet_mind'));
      expect(result.tags, contains('role_trial_aligned_music'));
      expect(result.tags, isNot(contains('role_comfort_only')));
      expect(result.tags, isNot(contains('role_masking_only')));
      expect(result.adFree, isTrue);
    });

    test('不喜欢指令的人得到环境化的核心音乐', () {
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
      expect(result.tags, contains('role_trial_aligned_music'));
      expect(result.tags, isNot(contains('guided')));
    });

    test('还不困时不再把普通科普或散文当作核心助眠内容', () {
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

      expect(result.kind, SessionKind.music);
      expect(result.tags, contains('role_trial_aligned_music'));
      expect(result.tags, isNot(contains('role_comfort_only')));
    });

    test('明确想听人声陪伴时仍然优先舒缓人声', () {
      final result = catalog.recommend(
        const UserProfile(
          onboardingComplete: true,
          supportNeed: SupportNeed.gentleCompany,
          soundPreference: SoundPreference.softVoice,
          guidancePreference: GuidancePreference.occasional,
        ),
        ContentRegion.mainlandChina,
      );

      expect(result.tags, contains('gentle_company'));
      expect(result.tags, contains('role_comfort_only'));
      expect(result.kind, anyOf(SessionKind.narrative, SessionKind.lecture));
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

    test('每条正式素材恰好属于一个证据角色', () {
      const roleTags = {
        'role_guided_relaxation',
        'role_trial_aligned_music',
        'role_supporting_music',
        'role_breathing_pacer',
        'role_masking_only',
        'role_comfort_only',
      };

      for (final item in catalog.items) {
        final roles = item.tags.intersection(roleTags);
        expect(roles, hasLength(1), reason: item.id);

        if (roles.contains('role_masking_only')) {
          expect(item.tags, contains('mask_noise'), reason: item.id);
          expect(item.tags, isNot(contains('quiet_mind')), reason: item.id);
          expect(item.tags, isNot(contains('relax_body')), reason: item.id);
          expect(item.tags, isNot(contains('not_sleepy')), reason: item.id);
        }

        if (roles.contains('role_breathing_pacer')) {
          expect(item.kind, SessionKind.breathingPacer, reason: item.id);
          expect(item.tags, contains('breathing'), reason: item.id);
          expect(item.tags, contains('low_stimulus'), reason: item.id);
          expect(item.tags, isNot(contains('night_awake')), reason: item.id);
        }

        if (roles.contains('role_comfort_only')) {
          expect(item.tags, isNot(contains('quiet_mind')), reason: item.id);
          expect(item.tags, isNot(contains('relax_body')), reason: item.id);
          expect(item.tags, isNot(contains('mask_noise')), reason: item.id);
          expect(item.tags, isNot(contains('not_sleepy')), reason: item.id);
          expect(item.tags, isNot(contains('night_awake')), reason: item.id);
        }

        if (roles.contains('role_trial_aligned_music')) {
          expect(item.kind, SessionKind.music, reason: item.id);
          expect(item.tags, contains('instrumental'), reason: item.id);
          expect(item.tags, contains('low_stimulus'), reason: item.id);
          if ((item.durationSeconds ?? 0) < 10 * 60) {
            expect(
              item.tags,
              contains('needs_long_form_master'),
              reason: item.id,
            );
          }
        }
      }
    });

    test('学习型犯困素材与核心目录隔离，并且冷启动不自动推荐', () {
      final study = catalog.studyDrowsyFor(ContentRegion.mainlandChina);
      expect(study, hasLength(3));
      expect(
        study.map((item) => item.id),
        containsAll({
          'study-zh-hydrochloric-acid',
          'study-zh-europe',
          'study-zh-wikipedia-2024',
        }),
      );
      expect(study.every((item) => item.kind == SessionKind.lecture), isTrue);
      expect(
        study.every((item) => item.playbackType == PlaybackType.directAudio),
        isTrue,
      );
      expect(study.every((item) => item.playbackUrl.scheme == 'https'), isTrue);
      expect(study.every((item) => item.tags.contains('study_drowsy')), isTrue);
      expect(
        study.every((item) => item.tags.contains('role_comfort_only')),
        isTrue,
      );
      expect(
        catalog.items.any((item) => item.tags.contains('study_drowsy')),
        isFalse,
      );

      final result = catalog.recommend(profile, ContentRegion.mainlandChina);
      expect(result.tags, isNot(contains('study_drowsy')));
    });

    test('一次正向反馈仍不自动推课程，两次后才按具体素材经验提高权重', () {
      final target = catalog.findById('study-zh-wikipedia-2024')!;
      var learned = profile.learnFrom(target, SessionFeedback.comfortable);

      expect(learned.tagAffinities['study_drowsy'], 2);
      expect(
        catalog.recommend(learned, ContentRegion.mainlandChina).tags,
        isNot(contains('study_drowsy')),
      );

      learned = learned.learnFrom(target, SessionFeedback.comfortable);
      final result = catalog.recommend(learned, ContentRegion.mainlandChina);
      expect(learned.tagAffinities['study_drowsy'], 4);
      expect(learned.sessionAffinities[target.id], 6);
      expect(result.id, target.id);
      expect(learned.tagAffinities.containsKey('low_pitch_screened'), isFalse);
    });

    test('同类课程有效也不会解锁没亲自验证过的另一门课', () {
      final proven = catalog.findById('study-zh-wikipedia-2024')!;
      final untried = catalog.findById('study-zh-hydrochloric-acid')!;
      var learned = profile;
      for (var index = 0; index < 3; index++) {
        learned = learned.learnFrom(proven, SessionFeedback.comfortable);
      }

      expect(learned.tagAffinities['study_drowsy'], 6);
      expect(learned.sessionAffinities[proven.id], 9);
      expect(learned.sessionAffinities[untried.id] ?? 0, 0);
      expect(
        catalog.recommend(learned, ContentRegion.mainlandChina).id,
        proven.id,
      );
    });

    test('学习型犯困偏好可以被后续不适合反馈撤销', () {
      final target = catalog.findById('study-zh-wikipedia-2024')!;
      var learned = profile
          .learnFrom(target, SessionFeedback.comfortable)
          .learnFrom(target, SessionFeedback.comfortable);
      expect(
        catalog.recommend(learned, ContentRegion.mainlandChina).id,
        target.id,
      );

      learned = learned.learnFrom(target, SessionFeedback.notForMe);
      expect(learned.tagAffinities['study_drowsy'], 2);
      expect(
        catalog.recommend(learned, ContentRegion.mainlandChina).tags,
        isNot(contains('study_drowsy')),
      );
    });

    test('国际区额外提供长篇 Logic 技术朗读', () {
      final study = catalog.studyDrowsyFor(ContentRegion.international);
      expect(study, hasLength(4));
      expect(
        study.map((item) => item.id),
        containsAll({
          'study-zh-hydrochloric-acid',
          'study-zh-europe',
          'study-zh-wikipedia-2024',
          'study-en-logic',
        }),
      );
      expect(
        study.every(
          (item) =>
              item.durationSeconds != null &&
              item.durationSeconds! >= 20 * 60 &&
              item.playbackType == PlaybackType.directAudio,
        ),
        isTrue,
      );
    });

    test('正式启动默认不加载候选库', () {
      expect(catalog.candidates, isEmpty);
      expect(
        catalog.candidateSessionsFor(ContentRegion.mainlandChina),
        isEmpty,
      );
      expect(catalog.items.every((item) => !item.isCandidate), isTrue);
      expect(catalog.studyItems.every((item) => !item.isCandidate), isTrue);
    });

    test('候选目录仅在显式评审模式加载，且不会进入正式推荐', () {
      final candidates = reviewCatalog.candidateSessionsFor(
        ContentRegion.mainlandChina,
      );
      expect(candidates.length, greaterThan(100));
      expect(candidates.every((item) => item.isCandidate), isTrue);
      expect(
        candidates.every(
          (item) =>
              item.playbackType == PlaybackType.directAudio &&
              item.playbackUrl.scheme == 'https' &&
              item.sourcePage.scheme == 'https' &&
              item.isPlaybackEligible,
        ),
        isTrue,
      );
      expect(
        candidates.every(
          (item) =>
              !item.tags.contains('quiet_mind') &&
              !item.tags.contains('not_sleepy'),
        ),
        isTrue,
      );
      expect(
        reviewCatalog
            .recommend(
              const UserProfile(onboardingComplete: true),
              ContentRegion.mainlandChina,
            )
            .isCandidate,
        isFalse,
      );
    });

    test('Wikimedia 中文候选使用 iOS 和 Android 都可播放的 MP3 转码', () {
      final wikimedia = reviewCatalog.candidates.where(
        (item) => item.provider == 'wikimediaCommons',
      );
      expect(wikimedia, isNotEmpty);
      expect(
        wikimedia.every((item) => item.playbackUrl.path.endsWith('.mp3')),
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
        }
      }
      for (final item in catalog.studyItems) {
        expect(item.playbackType, PlaybackType.directAudio, reason: item.id);
        expect(item.playbackUrl.scheme, 'https', reason: item.id);
        expect(item.assetPath, isNull, reason: item.id);
      }
    });

    test('精简后的核心素材全部离线可用，并保留中文人声层次', () {
      final china = catalog.sessionsFor(ContentRegion.mainlandChina);
      final international = catalog.sessionsFor(ContentRegion.international);
      expect(china.length, 11);
      expect(international.length, 12);
      expect(catalog.items.length, 12);
      expect(
        catalog.items.every(
          (item) => item.playbackType == PlaybackType.assetAudio,
        ),
        isTrue,
      );
      expect(catalog.spokenFor(ContentRegion.mainlandChina).length, 4);
      expect(catalog.spokenFor(ContentRegion.international).length, 5);
    });

    test('核心两条试验范式音乐已经是长版 master', () {
      for (final id in ['music-first-light', 'music-contemplation']) {
        final item = catalog.findById(id)!;
        expect(item.durationSeconds, 1500, reason: id);
        expect(item.loop, isFalse, reason: id);
        expect(item.tags, contains('long_form_master'), reason: id);
        expect(
          item.tags,
          isNot(contains('needs_long_form_master')),
          reason: id,
        );
      }
    });

    test('慢呼吸节拍独立存在，不冒充音乐或夜醒素材', () {
      final item = catalog.findById('breathing-coherent-gong')!;
      expect(item.kind, SessionKind.breathingPacer);
      expect(item.durationSeconds, 1200);
      expect(item.loop, isFalse);
      expect(item.tags, contains('role_breathing_pacer'));
      expect(item.tags, contains('breathing'));
      expect(item.tags, contains('quiet_mind'));
      expect(item.tags, contains('relax_body'));
      expect(item.tags, isNot(contains('night_awake')));
      expect(item.rightsStatus, 'cc0');
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
          sessions.any((item) => item.tags.contains('ambient')),
          isTrue,
          reason: '$region 缺少纯环境声',
        );
      }
      expect(
        catalog
            .sessionsFor(ContentRegion.international)
            .any((item) => item.tags.contains('guided')),
        isTrue,
      );
    });

    test('中文区同时提供音乐、长短中文女声和自然声', () {
      final china = catalog.sessionsFor(ContentRegion.mainlandChina);
      expect(china.where((item) => item.kind == SessionKind.music).length, 3);
      expect(
        china.where((item) => item.kind == SessionKind.narrative).length,
        3,
      );
      expect(
        china
            .where(
              (item) =>
                  item.kind == SessionKind.narrative &&
                  item.languageCode == 'zh' &&
                  (item.durationSeconds ?? 0) >= 30 * 60,
            )
            .length,
        1,
      );
      expect(china.where((item) => item.kind == SessionKind.lecture).length, 1);
      expect(
        china.where((item) => item.tags.contains('nature')).length,
        greaterThanOrEqualTo(2),
      );
    });

    test('夜醒默认不把遮噪音当作普通用户首选', () {
      final result = catalog.recommendNightRescue(
        profile,
        ContentRegion.mainlandChina,
      );
      expect(result.kind, isNot(SessionKind.lecture));
      expect(result.tags, contains('night_awake'));
      expect(result.tags, isNot(contains('role_masking_only')));
      expect(result.isPlaybackEligible, isTrue);
    });

    test('明确需要遮噪时夜醒推荐可使用遮噪素材', () {
      final result = catalog.recommendNightRescue(
        const UserProfile(
          onboardingComplete: true,
          supportNeed: SupportNeed.maskNoise,
          soundPreference: SoundPreference.nature,
        ),
        ContentRegion.mainlandChina,
      );
      expect(result.tags, contains('role_masking_only'));
      expect(result.tags, contains('mask_noise'));
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
      expect(
        learned.tagAffinities.containsKey('role_supporting_music'),
        isFalse,
      );
      expect(learned.tagAffinities.containsKey('short_loop_risk'), isFalse);
      expect(learned.tagAffinities.containsKey('long_form_master'), isFalse);
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
