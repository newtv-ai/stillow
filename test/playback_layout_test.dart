import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/data/content_catalog.dart';
import 'package:stillow/domain/sleep_history.dart';
import 'package:stillow/domain/stillow_models.dart';
import 'package:stillow/features/night/night_rescue_screen.dart';
import 'package:stillow/features/player/player_screen.dart';
import 'package:stillow/features/session/session_library_screen.dart';
import 'package:stillow/features/user_sound/user_sound_library_screen.dart';
import 'package:stillow/l10n/l10n.dart';
import 'package:stillow/services/offline_audio_store.dart';
import 'package:stillow/services/remote_audio_controller.dart';
import 'package:stillow/theme/stillow_theme.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await ContentCatalog.loadAsset();
  });

  testWidgets('播放器在矮屏、横屏和大字体下不溢出', (tester) async {
    final session = catalog.findById('guided-body-scan-female-en')!;
    final controller = FakeSleepPlaybackController();

    await _pumpOverflowCases(tester, () {
      return _localizedTestApp(
        home: PlayerScreen(
          item: PlaybackItem.fromGuidedSession(session),
          playbackController: controller,
          onPlaybackStarted: (_, _) async {},
          onSessionFinished: (_) async {},
        ),
      );
    });
  });

  testWidgets('夜醒页在矮屏、横屏和大字体下不溢出', (tester) async {
    await _pumpOverflowCases(tester, () {
      return _localizedTestApp(
        home: NightRescueScreen(
          profile: const UserProfile(onboardingComplete: true),
          catalog: catalog,
          region: ContentRegion.mainlandChina,
          offlineAudioStore: OfflineAudioStore(
            directoryProvider: () async =>
                throw StateError('layout test does not download'),
          ),
          userSounds: const [],
          onNightPresetChanged: (_) async {},
          onPlaybackStarted: (_, _) async {},
          onSessionFinished: (_) async {},
        ),
      );
    });
  });

  testWidgets('素材库在横屏和大字体下不溢出', (tester) async {
    await _pumpOverflowCases(tester, () {
      return _localizedTestApp(
        home: SessionLibraryScreen(
          sessions: catalog.sessionsFor(ContentRegion.mainlandChina),
          favoriteSessionIds: const {},
          onFavoriteChanged: (_) async {},
          offlineAudioStore: OfflineAudioStore(
            directoryProvider: () async =>
                throw StateError('layout test does not download'),
          ),
        ),
      );
    });
  });

  testWidgets('我的声音在矮屏、横屏和大字体下不溢出', (tester) async {
    final sound = UserSound(
      id: 'layout',
      title: '一段名称比较长但仍然容易辨认的熟悉声音',
      sourceKind: UserSoundSourceKind.fileCopy,
      relativePath: '1.mp3',
      originalFileName: 'sound.mp3',
      loop: true,
      attenuateLoops: true,
      createdAt: DateTime(2026),
      localFilePath: 'C:/private/1.mp3',
    );
    await _pumpOverflowCases(tester, () {
      return _localizedTestApp(
        home: UserSoundLibraryScreen(
          initialSounds: [sound],
          onImport: (_) async => const [],
          onCancelImport: () {},
          onUsageRequested: () async => 1024 * 1024,
          onUpdate: (value) async => value,
          onDelete: (_) async {},
          onReorder: (_) async {},
        ),
      );
    });
  });

  testWidgets('播放器状态机覆盖开始、暂停、完成和记录收尾', (tester) async {
    final session = catalog.findById('music-first-light')!;
    final controller = FakeSleepPlaybackController();
    PlaybackItem? started;
    AppSleepSessionRecord? finished;

    await tester.pumpWidget(
      _localizedTestApp(
        home: PlayerScreen(
          item: PlaybackItem.fromGuidedSession(session),
          playbackController: controller,
          onPlaybackStarted: (value, _) async => started = value,
          onSessionFinished: (value) async => finished = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('播放'));
    await tester.pump();
    await tester.pump();

    expect(controller.status, PlaybackStatus.playing);
    expect(started?.id, session.id);
    expect(find.byTooltip('暂停'), findsOneWidget);

    await tester.tap(find.byTooltip('暂停'));
    await tester.pump();
    expect(controller.status, PlaybackStatus.paused);

    await tester.tap(find.byTooltip('播放'));
    await tester.pump();
    expect(controller.status, PlaybackStatus.playing);

    controller.emitComplete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(finished?.sessionId, session.id);
    expect(finished?.listenedSeconds, greaterThanOrEqualTo(1));
    expect(find.text('声音已经慢慢停下'), findsOneWidget);
  });

  testWidgets('个人声音使用本机标识、自己的计时设置和独立播放来源', (tester) async {
    final sound = UserSound(
      id: 'mine',
      title: '熟悉的课程',
      sourceKind: UserSoundSourceKind.fileCopy,
      relativePath: '1.mp3',
      originalFileName: 'lesson.mp3',
      loop: true,
      attenuateLoops: true,
      defaultTimerMinutes: 15,
      createdAt: DateTime(2026),
      localFilePath: 'C:/private/1.mp3',
    );
    final item = PlaybackItem.fromUserSound(
      sound,
      subtitle: '来自你的本机音频',
      shortLabel: '我的声音',
      creatorLabel: '本机文件',
    );
    final controller = FakeSleepPlaybackController();
    PlaybackItem? started;

    await tester.pumpWidget(
      _localizedTestApp(
        home: PlayerScreen(
          item: item,
          playbackController: controller,
          defaultSleepTimer: const Duration(minutes: 15),
          onPlaybackStarted: (value, _) async => started = value,
          onSessionFinished: (_) async {},
        ),
      ),
    );
    await tester.tap(find.byTooltip('播放'));
    await tester.pump();

    expect(started?.isUserSound, isTrue);
    expect(controller.item?.userSound?.id, sound.id);
    expect(controller.sleepTimerEndsAt, isNotNull);
    expect(find.text('我的声音 · 仅保存在本机'), findsOneWidget);
    expect(find.textContaining('LibriVox'), findsNothing);
  });

  testWidgets('个人声音列表在一首结束后继续下一首', (tester) async {
    UserSound sound(String id, String title) => UserSound(
      id: id,
      title: title,
      sourceKind: UserSoundSourceKind.devicePath,
      originalFileName: '$id.mp3',
      loop: false,
      attenuateLoops: false,
      createdAt: DateTime(2026),
      sourcePath: 'C:/private/$id.mp3',
      localFilePath: 'C:/private/$id.mp3',
    );
    final first = sound('one', '第一课');
    final second = sound('two', '第二课');
    PlaybackItem itemOf(UserSound value) => PlaybackItem.fromUserSound(
      value,
      subtitle: '来自你的本机音频',
      shortLabel: '我的声音',
      creatorLabel: '本机文件',
    );
    final controller = FakeSleepPlaybackController();
    final started = <String>[];

    await tester.pumpWidget(
      _localizedTestApp(
        home: PlayerScreen(
          item: itemOf(first),
          playlist: [itemOf(first), itemOf(second)],
          playbackController: controller,
          onPlaybackStarted: (value, _) async => started.add(value.id),
          onSessionFinished: (_) async {},
        ),
      ),
    );
    await tester.tap(find.byTooltip('播放'));
    await tester.pump();

    expect(find.text('第一课'), findsWidgets);
    expect(find.text('1 / 2'), findsOneWidget);

    controller.emitComplete();
    await tester.pump();
    await tester.pump();

    expect(controller.item?.userSound?.id, 'two');
    expect(find.text('第二课'), findsWidgets);
    expect(started, ['user:one', 'user:two']);
  });

  testWidgets('从播放列表拿掉后不再播放那一条', (tester) async {
    UserSound sound(String id, String title) => UserSound(
      id: id,
      title: title,
      sourceKind: UserSoundSourceKind.devicePath,
      originalFileName: '$id.mp3',
      loop: false,
      attenuateLoops: false,
      createdAt: DateTime(2026),
      sourcePath: 'C:/private/$id.mp3',
      localFilePath: 'C:/private/$id.mp3',
    );
    PlaybackItem itemOf(UserSound value) => PlaybackItem.fromUserSound(
      value,
      subtitle: '来自你的本机音频',
      shortLabel: '我的声音',
      creatorLabel: '本机文件',
    );
    final first = sound('one', '第一课');
    final second = sound('two', '第二课');
    final controller = FakeSleepPlaybackController();
    final removed = <String>[];

    await tester.pumpWidget(
      _localizedTestApp(
        home: PlayerScreen(
          item: itemOf(first),
          playlist: [itemOf(first), itemOf(second)],
          playbackController: controller,
          onPlaybackStarted: (_, _) async {},
          onSessionFinished: (_) async {},
          onRemoveFromPlaylist: (item) async {
            removed.add(item.userSound!.id);
          },
        ),
      ),
    );
    await tester.tap(find.byTooltip('播放'));
    await tester.pump();
    await tester.scrollUntilVisible(find.byTooltip('从列表拿掉').first, 200);
    await tester.tap(find.byTooltip('从列表拿掉').first);
    await tester.pump();
    await tester.pump();

    expect(removed, ['one']);
    expect(controller.item?.userSound?.id, 'two');
    expect(find.text('第一课'), findsNothing);
    expect(find.text('第二课'), findsWidgets);
  });

  testWidgets('夜醒播放器与睡前使用同一套淡出选项', (tester) async {
    final session = catalog.recommendNightRescue(
      const UserProfile(onboardingComplete: true),
      ContentRegion.mainlandChina,
    );

    await tester.pumpWidget(
      _localizedTestApp(
        home: PlayerScreen(
          item: PlaybackItem.fromGuidedSession(session),
          playbackController: FakeSleepPlaybackController(),
          nightMode: true,
          onPlaybackStarted: (_, _) async {},
          onSessionFinished: (_) async {},
        ),
      ),
    );
    await tester.tap(find.text('设置淡出时间'));
    await tester.pumpAndSettle();

    expect(find.text('15 分钟'), findsOneWidget);
    expect(find.text('30 分钟'), findsOneWidget);
    expect(find.text('45 分钟'), findsOneWidget);
    expect(find.text('60 分钟'), findsOneWidget);
    expect(find.text('不定时'), findsOneWidget);
    expect(find.text('5 分钟'), findsNothing);
    expect(find.text('10 分钟'), findsNothing);
  });
}

Future<void> _pumpOverflowCases(
  WidgetTester tester,
  Widget Function() wrap,
) async {
  const cases = [
    Size(360, 640),
    Size(320, 568),
    Size(640, 360),
    Size(390, 844),
  ];
  const scales = [1.0, 1.3, 2.0];

  for (final size in cases) {
    for (final scale in scales) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      final overflows = <String>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('overflowed') || text.contains('RenderFlex')) {
          overflows.add('$size @${scale}x\n$text');
        } else {
          original?.call(details);
        }
      };

      try {
        await tester.pumpWidget(wrap());
        await tester.pump();
      } finally {
        FlutterError.onError = original;
      }
      expect(overflows, isEmpty, reason: overflows.join('\n---\n'));
      expect(tester.takeException(), isNull);
    }
  }
}

Widget _localizedTestApp({
  required Widget home,
  Locale locale = const Locale('zh'),
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: StillowTheme.dark,
  home: home,
);
