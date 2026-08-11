import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/app.dart';
import 'package:stillow/data/content_catalog.dart';
import 'package:stillow/domain/sleep_history.dart';
import 'package:stillow/domain/stillow_models.dart';
import 'package:stillow/features/history/sleep_history_screen.dart';
import 'package:stillow/features/morning/morning_review_screen.dart';
import 'package:stillow/features/session/session_library_screen.dart';
import 'package:stillow/services/offline_audio_store.dart';
import 'package:stillow/theme/stillow_theme.dart';
import 'package:stillow/widgets/soft_ui.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await ContentCatalog.loadAsset();
  });

  testWidgets('新用户可以轻松完成三步首次选择', (tester) async {
    final store = MemoryPreferenceStore();

    await tester.pumpWidget(
      StillowApp(
        initialProfile: const UserProfile(),
        preferenceStore: store,
        catalog: catalog,
        region: ContentRegion.mainlandChina,
        sleepHistoryStore: MemorySleepHistoryStore(),
        sleepHealthGateway: MemorySleepHealthGateway(),
      ),
    );

    expect(find.text('今晚，你更希望得到哪种陪伴？'), findsOneWidget);
    expect(find.text('先随便听听'), findsOneWidget);

    await tester.tap(find.text('想法停不下来'));
    await tester.pump();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('轻轻说话，或不必听懂的课程'));
    await tester.pump();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('偶尔提醒一下就好'));
    await tester.pump();
    await tester.tap(find.text('今晚先试试'));
    await tester.pumpAndSettle();

    expect(find.text('今晚不用完成\n任何任务。'), findsOneWidget);
    expect(store.profile.onboardingComplete, isTrue);
    expect(store.profile.supportNeed, SupportNeed.quietMind);
  });

  testWidgets('声音偏好的四个选项在常见窄屏内完整显示', (tester) async {
    tester.view.devicePixelRatio = 2.5;
    tester.view.physicalSize = const Size(920, 2048);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      StillowApp(
        initialProfile: const UserProfile(),
        preferenceStore: MemoryPreferenceStore(),
        catalog: catalog,
        region: ContentRegion.mainlandChina,
        sleepHistoryStore: MemorySleepHistoryStore(),
        sleepHealthGateway: MemorySleepHealthGateway(),
      ),
    );

    await tester.tap(find.text('想法停不下来'));
    await tester.pump();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    const choices = ['轻轻说话，或不必听懂的课程', '熟悉、平缓的音乐', '雨声、风声等环境声', '更喜欢安静，只要少量提示'];
    expect(find.byType(SoftChoiceCard), findsNWidgets(4));
    for (final choice in choices) {
      expect(find.text(choice).hitTestable(), findsOneWidget);
    }

    final lastCard = find.widgetWithText(SoftChoiceCard, choices.last);
    final continueButton = find.widgetWithText(FilledButton, '继续');
    expect(
      tester.getBottomRight(lastCard).dy,
      lessThan(tester.getTopLeft(continueButton).dy),
    );
  });

  testWidgets('已完成首次选择的用户直接看到低压力首页', (tester) async {
    final profile = const UserProfile(
      onboardingComplete: true,
      supportNeed: SupportNeed.relaxBody,
      soundPreference: SoundPreference.softVoice,
      guidancePreference: GuidancePreference.stepByStep,
    );

    await tester.pumpWidget(
      StillowApp(
        initialProfile: profile,
        preferenceStore: MemoryPreferenceStore(profile),
        catalog: catalog,
        region: ContentRegion.mainlandChina,
        sleepHistoryStore: MemorySleepHistoryStore(),
        sleepHealthGateway: MemorySleepHealthGateway(),
      ),
    );

    expect(find.text('今晚先试试'), findsOneWidget);
    expect(find.text('跟着身体扫描慢慢松开'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('听一段不必学会的课'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('听一段不必学会的课'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('夜里醒来时'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('夜里醒来时'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('醒来以后'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('醒来以后'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('最近的夜晚'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('最近的夜晚'), findsOneWidget);
    expect(find.text('睡眠分数'), findsNothing);
  });

  testWidgets('晨间回顾不打分，梦境解析显示娱乐边界', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: StillowTheme.dark, home: const MorningReviewScreen()),
    );

    await tester.tap(find.text('还是有点累'));
    await tester.pump();
    expect(find.text('昨晚似乎没有休息得很舒服。'), findsOneWidget);
    expect(find.textContaining('不是睡眠分数'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('看看我的梦'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pump();
    await tester.tap(find.text('看看我的梦'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '我在陌生的房子里看着窗外下雨');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('看看这个梦'));
    await tester.tap(find.text('看看这个梦'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('空间与内心角落'), findsOneWidget);
    expect(find.textContaining('仅供休闲娱乐'), findsOneWidget);
    expect(find.textContaining('退出后不保存'), findsOneWidget);
  });

  testWidgets('素材库可搜索、显示离线状态并收藏', (tester) async {
    final directory = Directory.systemTemp.createTempSync(
      'stillow_library_test_',
    );
    final offlineStore = OfflineAudioStore(
      directoryProvider: () async => directory,
    );
    addTearDown(() {
      offlineStore.dispose();
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });
    String? favoriteId;

    await tester.pumpWidget(
      MaterialApp(
        theme: StillowTheme.dark,
        home: SessionLibraryScreen(
          sessions: catalog.sessionsFor(ContentRegion.mainlandChina),
          favoriteSessionIds: const {},
          onFavoriteChanged: (sessionId) async => favoriteId = sessionId,
          offlineAudioStore: offlineStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '星野');
    await tester.pumpAndSettle();

    expect(find.text('慢慢漂过星野'), findsOneWidget);
    expect(find.text('离线可用'), findsOneWidget);
    await tester.tap(find.byTooltip('收藏'));
    await tester.pump();
    expect(favoriteId, 'music-starfield');
    expect(find.byTooltip('取消收藏'), findsOneWidget);
  });

  testWidgets('睡眠历史只展示记录走势，不生成质量评分', (tester) async {
    final now = DateTime.now();
    final historyStore = MemorySleepHistoryStore(
      SleepHistorySnapshot(
        appSessions: [
          AppSleepSessionRecord(
            id: 'session-1',
            startedAt: now.subtract(const Duration(hours: 9)),
            sessionId: 'rain',
            sessionTitle: '轻雨',
            context: SleepUseContext.bedtime,
            listenedSeconds: 1200,
          ),
        ],
        healthSamples: [
          HealthSleepSample(
            id: 'health-1',
            startedAt: now.subtract(const Duration(hours: 8)),
            endedAt: now,
            stage: HealthSleepStage.session,
          ),
        ],
        lastHealthSyncAt: now,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: StillowTheme.dark,
        home: SleepHistoryScreen(
          historyStore: historyStore,
          healthGateway: MemorySleepHealthGateway(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('睡眠记录时段走势'), findsOneWidget);
    expect(find.textContaining('不是睡眠质量分数'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('轻雨'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('轻雨'), findsOneWidget);
    expect(find.text('睡眠质量评分'), findsNothing);
  });
}
