import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stillow/domain/stillow_models.dart';
import 'package:stillow/services/remote_audio_controller.dart';
import 'package:stillow/services/user_sound_access.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('等待中的访问释放完成后会继续释放期间出现的新句柄', () async {
    final player = _FakeAudioPlayer();
    final access = _OutOfOrderAccess();
    final controller = RemoteAudioController(
      player: player,
      userSoundAccess: access,
    );
    addTearDown(controller.dispose);

    final firstStart = controller.start(_item('first'));
    await access.firstBeginStarted.future;

    await controller.start(_item('second'));
    final firstStop = controller.stop();
    await access.firstReleaseStarted.future;

    access.completeFirstBegin();
    await firstStart;

    final secondStop = controller.stop();
    access.completeFirstRelease();
    await Future.wait([firstStop, secondStop]);

    expect(access.endPlaybackCalls, 2);
  });
}

PlaybackItem _item(String id) {
  return PlaybackItem.fromUserSound(
    UserSound(
      id: id,
      title: id,
      sourceKind: UserSoundSourceKind.devicePath,
      originalFileName: '$id.mp3',
      sourcePath: '/sounds/$id.mp3',
      accessBookmark: 'bookmark-$id',
      loop: false,
      attenuateLoops: false,
      createdAt: DateTime(2026),
    ),
    subtitle: '',
    shortLabel: '',
    creatorLabel: '',
  );
}

final class _OutOfOrderAccess extends UserSoundAccess {
  final firstBeginStarted = Completer<void>();
  final firstReleaseStarted = Completer<void>();
  final _firstBegin = Completer<UserSoundPlaybackHandle>();
  final _firstRelease = Completer<void>();
  int beginPlaybackCalls = 0;
  int endPlaybackCalls = 0;

  void completeFirstBegin() {
    _firstBegin.complete(
      const UserSoundPlaybackHandle(filePath: '/sounds/first.mp3'),
    );
  }

  void completeFirstRelease() => _firstRelease.complete();

  @override
  Future<UserSoundPlaybackHandle> beginPlayback({
    required String sourcePath,
    String? accessBookmark,
  }) {
    beginPlaybackCalls++;
    if (beginPlaybackCalls == 1) {
      firstBeginStarted.complete();
      return _firstBegin.future;
    }
    return Future.value(UserSoundPlaybackHandle(filePath: sourcePath));
  }

  @override
  Future<void> endPlayback() {
    endPlaybackCalls++;
    if (endPlaybackCalls == 1) {
      firstReleaseStarted.complete();
      return _firstRelease.future;
    }
    return Future.value();
  }

  @override
  Future<UserSoundAccessCheck> ensureReadable({
    required String sourcePath,
    String? accessBookmark,
    bool Function()? isCancelled,
  }) async => UserSoundAccessCheck.ok;

  @override
  Future<void> persist(String sourcePath) async {}

  @override
  Future<String?> refreshBookmark({
    required String sourcePath,
    required String accessBookmark,
  }) async => accessBookmark;

  @override
  Future<void> release(String sourcePath) async {}
}

final class _FakeAudioPlayer extends AudioPlayer {
  final _states = StreamController<PlayerState>.broadcast();
  final _positions = StreamController<Duration>.broadcast();

  @override
  Stream<PlayerState> get playerStateStream => _states.stream;

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  Future<Duration?> setAudioSource(
    AudioSource audioSource, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async => const Duration(minutes: 30);

  @override
  Future<void> setLoopMode(LoopMode mode) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _states.close();
    await _positions.close();
  }
}
