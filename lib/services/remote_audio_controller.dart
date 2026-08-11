import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../domain/stillow_models.dart';

enum PlaybackStatus { idle, loading, playing, paused, complete, error }

class RemoteAudioController extends ChangeNotifier {
  RemoteAudioController({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    _playerSubscription = _player.playerStateStream.listen(_handlePlayerState);
  }

  final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _playerSubscription;
  Timer? _sleepTimer;

  PlaybackStatus status = PlaybackStatus.idle;
  GuidedSession? session;
  String? errorMessage;
  DateTime? sleepTimerEndsAt;

  bool get isPlaying => status == PlaybackStatus.playing;
  Future<void> start(GuidedSession nextSession) async {
    if (!nextSession.isInAppAudio) {
      throw ArgumentError('不支持的素材不能交给音频播放器');
    }

    session = nextSession;
    errorMessage = null;
    status = PlaybackStatus.loading;
    notifyListeners();

    try {
      await _player.setVolume(1);
      await _player.setLoopMode(nextSession.loop ? LoopMode.one : LoopMode.off);
      final mediaItem = MediaItem(
        id: nextSession.id,
        album: 'Stillow 夜间陪伴',
        title: nextSession.title,
        artist: nextSession.creator,
        duration: nextSession.durationSeconds == null
            ? null
            : Duration(seconds: nextSession.durationSeconds!),
      );
      if (nextSession.localFilePath case final localFilePath?) {
        await _player.setAudioSource(
          AudioSource.file(localFilePath, tag: mediaItem),
        );
      } else if (nextSession.playbackType == PlaybackType.assetAudio) {
        final assetPath = nextSession.assetPath;
        if (assetPath == null || assetPath.isEmpty) {
          throw const FormatException('本地素材缺少 assetPath');
        }
        await _player.setAudioSource(
          AudioSource.asset(assetPath, tag: mediaItem),
        );
      } else {
        await _player.setAudioSource(
          AudioSource.uri(nextSession.playbackUrl, tag: mediaItem),
        );
      }
      unawaited(_play());
    } on PlayerException catch (_) {
      _setError('暂时没能载入这段声音，可以换一个试试。');
    } on PlayerInterruptedException catch (_) {
      _setError('声音载入被打断了，可以稍后再试。');
    } catch (_) {
      _setError('这段声音暂时不可用，可以换一个试试。');
    }
  }

  Future<void> _play() async {
    try {
      await _player.play();
    } on PlayerException catch (_) {
      _setError('播放中断了，可以重新播放或换一个声音。');
    } catch (_) {
      _setError('播放中断了，可以换一个声音试试。');
    }
  }

  Future<void> resume() async {
    if (session == null || status == PlaybackStatus.complete) return;
    unawaited(_play());
  }

  Future<void> pause() => _player.pause();

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerEndsAt = duration == null ? null : DateTime.now().add(duration);
    unawaited(_player.setVolume(1));
    notifyListeners();
    if (duration == null) return;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final endsAt = sleepTimerEndsAt;
      if (endsAt == null) {
        timer.cancel();
        return;
      }
      final remaining = endsAt.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        timer.cancel();
        sleepTimerEndsAt = null;
        unawaited(stop());
        return;
      }
      if (remaining <= const Duration(seconds: 30)) {
        final volume = (remaining.inMilliseconds / 30000).clamp(0.0, 1.0);
        unawaited(_player.setVolume(volume));
      }
      notifyListeners();
    });
  }

  Future<void> stop() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerEndsAt = null;
    await _player.stop();
    await _player.setVolume(1);
    status = PlaybackStatus.idle;
    notifyListeners();
  }

  void _handlePlayerState(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.completed) {
      _sleepTimer?.cancel();
      _sleepTimer = null;
      sleepTimerEndsAt = null;
    }
    status = switch (playerState.processingState) {
      ProcessingState.loading ||
      ProcessingState.buffering => PlaybackStatus.loading,
      ProcessingState.completed => PlaybackStatus.complete,
      ProcessingState.idle when session == null => PlaybackStatus.idle,
      _ when playerState.playing => PlaybackStatus.playing,
      _ when session != null => PlaybackStatus.paused,
      _ => PlaybackStatus.idle,
    };
    notifyListeners();
  }

  void _setError(String message) {
    errorMessage = message;
    status = PlaybackStatus.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    unawaited(_playerSubscription.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
