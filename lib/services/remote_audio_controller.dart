import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../domain/stillow_models.dart';
import 'progressive_loop_volume.dart';
import 'user_sound_access.dart';

enum PlaybackStatus { idle, loading, playing, paused, complete, error }

enum PlaybackFailure {
  loadFailed,
  loadInterrupted,
  unavailable,
  stoppedRetry,
  stopped,
}

abstract class SleepPlaybackController extends ChangeNotifier {
  PlaybackStatus get status;
  PlaybackFailure? get failure;
  DateTime? get sleepTimerEndsAt;
  bool get isPlaying;

  Future<void> start(PlaybackItem item);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  void setSleepTimer(Duration? duration);
}

class RemoteAudioController extends SleepPlaybackController {
  RemoteAudioController({AudioPlayer? player, UserSoundAccess? userSoundAccess})
    : _player = player ?? AudioPlayer(),
      _userSoundAccess = userSoundAccess ?? const PluginUserSoundAccess() {
    _playerSubscription = _player.playerStateStream.listen(_handlePlayerState);
    _positionSubscription = _player.positionStream.listen(_handlePosition);
  }

  final AudioPlayer _player;
  final UserSoundAccess _userSoundAccess;
  UserSoundPlaybackHandle? _playbackHandle;
  Future<void>? _accessRelease;
  bool _finishingCompletion = false;
  int _playbackGeneration = 0;
  bool _disposed = false;
  static const _loopVolume = ProgressiveLoopVolume();
  late final StreamSubscription<PlayerState> _playerSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  Timer? _sleepTimer;
  Duration _previousPosition = Duration.zero;
  int _completedMusicLoops = 0;
  double _loopGain = 1;
  double _fadeGain = 1;
  bool _attenuateMusicLoops = false;

  @override
  PlaybackStatus status = PlaybackStatus.idle;
  PlaybackItem? item;
  @override
  PlaybackFailure? failure;
  @override
  DateTime? sleepTimerEndsAt;

  @override
  bool get isPlaying => status == PlaybackStatus.playing;

  @override
  Future<void> start(PlaybackItem nextItem) async {
    final generation = ++_playbackGeneration;
    item = nextItem;
    _previousPosition = Duration.zero;
    _completedMusicLoops = 0;
    _loopGain = 1;
    _fadeGain = 1;
    _attenuateMusicLoops = nextItem.attenuateLoops;
    failure = null;
    status = PlaybackStatus.loading;
    notifyListeners();

    try {
      await _endPlaybackAccess();
      var filePath = nextItem.localFilePath;
      var playbackUrl = nextItem.playbackUrl;
      final userSound = nextItem.userSound;
      if (userSound != null) {
        _playbackHandle = await _userSoundAccess.beginPlayback(
          sourcePath: userSound.sourcePath ?? userSound.localFilePath ?? '',
          accessBookmark: userSound.accessBookmark,
        );
        filePath = _playbackHandle?.filePath ?? filePath;
        playbackUrl = _playbackHandle?.uri ?? playbackUrl;
      }
      if ((filePath == null || filePath.isEmpty) &&
          nextItem.assetPath == null &&
          playbackUrl == null) {
        throw ArgumentError('不支持的素材不能交给音频播放器');
      }
      await _applyVolume();
      await _player.setLoopMode(nextItem.loop ? LoopMode.one : LoopMode.off);
      final mediaItem = MediaItem(
        id: nextItem.id,
        album: 'Stillow',
        title: nextItem.title,
        artist: nextItem.creator,
        duration: nextItem.durationSeconds == null
            ? null
            : Duration(seconds: nextItem.durationSeconds!),
      );
      if (filePath != null &&
          filePath.isNotEmpty &&
          !filePath.startsWith('content:')) {
        await _player.setAudioSource(
          AudioSource.file(filePath, tag: mediaItem),
        );
      } else if (nextItem.playbackType == PlaybackType.assetAudio) {
        final assetPath = nextItem.assetPath;
        if (assetPath == null || assetPath.isEmpty) {
          throw const FormatException('本地素材缺少 assetPath');
        }
        await _player.setAudioSource(
          AudioSource.asset(assetPath, tag: mediaItem),
        );
      } else {
        await _player.setAudioSource(
          AudioSource.uri(playbackUrl!, tag: mediaItem),
        );
      }
      unawaited(_play(generation));
    } on PlayerException catch (_) {
      await _endPlaybackAccess();
      _setError(PlaybackFailure.loadFailed);
    } on PlayerInterruptedException catch (_) {
      await _endPlaybackAccess();
      _setError(PlaybackFailure.loadInterrupted);
    } catch (_) {
      await _endPlaybackAccess();
      _setError(PlaybackFailure.unavailable);
    }
  }

  Future<void> _play(int generation) async {
    try {
      await _player.play();
    } on PlayerException catch (_) {
      if (generation != _playbackGeneration) return;
      await _endPlaybackAccess();
      _setError(PlaybackFailure.stoppedRetry);
    } catch (_) {
      if (generation != _playbackGeneration) return;
      await _endPlaybackAccess();
      _setError(PlaybackFailure.stopped);
    }
  }

  @override
  Future<void> resume() async {
    if (item == null || status == PlaybackStatus.complete) return;
    unawaited(_play(_playbackGeneration));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerEndsAt = duration == null ? null : DateTime.now().add(duration);
    _fadeGain = 1;
    unawaited(_applyVolume());
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
        final nextFade = (remaining.inMilliseconds / 30000)
            .clamp(0.0, 1.0)
            .toDouble();
        if (nextFade != _fadeGain) {
          _fadeGain = nextFade;
          unawaited(_applyVolume());
          notifyListeners();
        }
      }
    });
  }

  @override
  Future<void> stop() async {
    _playbackGeneration++;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerEndsAt = null;
    await _player.stop();
    await _endPlaybackAccess();
    item = null;
    _previousPosition = Duration.zero;
    _completedMusicLoops = 0;
    _loopGain = 1;
    _fadeGain = 1;
    _attenuateMusicLoops = false;
    await _applyVolume();
    status = PlaybackStatus.idle;
    if (!_disposed) notifyListeners();
  }

  void _handlePosition(Duration position) {
    if (_disposed) return;
    if (_attenuateMusicLoops &&
        status == PlaybackStatus.playing &&
        ProgressiveLoopVolume.didPositionWrap(_previousPosition, position)) {
      _completedMusicLoops++;
      _loopGain = _loopVolume.gainForCompletedLoops(_completedMusicLoops);
      unawaited(_applyVolume());
    }
    _previousPosition = position;
  }

  Future<void> _applyVolume() {
    final volume = (_loopGain * _fadeGain).clamp(0.0, 1.0).toDouble();
    return _player.setVolume(volume);
  }

  void _handlePlayerState(PlayerState playerState) {
    if (_disposed) return;
    if (playerState.processingState == ProcessingState.completed) {
      _sleepTimer?.cancel();
      _sleepTimer = null;
      sleepTimerEndsAt = null;
      if (!_finishingCompletion) {
        _finishingCompletion = true;
        unawaited(_finishCompleted(item, _playbackGeneration));
      }
      return;
    }
    status = switch (playerState.processingState) {
      ProcessingState.loading ||
      ProcessingState.buffering => PlaybackStatus.loading,
      ProcessingState.completed => PlaybackStatus.complete,
      ProcessingState.idle when item == null => PlaybackStatus.idle,
      _ when playerState.playing => PlaybackStatus.playing,
      _ when item != null => PlaybackStatus.paused,
      _ => PlaybackStatus.idle,
    };
    notifyListeners();
  }

  Future<void> _finishCompleted(
    PlaybackItem? completedItem,
    int completedGeneration,
  ) async {
    await _endPlaybackAccess();
    if (_playbackGeneration == completedGeneration &&
        identical(item, completedItem) &&
        !_disposed) {
      status = PlaybackStatus.complete;
      notifyListeners();
    }
    _finishingCompletion = false;
  }

  void _setError(PlaybackFailure nextFailure) {
    if (_disposed) return;
    failure = nextFailure;
    status = PlaybackStatus.error;
    notifyListeners();
  }

  Future<void> _endPlaybackAccess() async {
    final pendingRelease = _accessRelease;
    if (pendingRelease != null) {
      await pendingRelease;
    }
    final handle = _playbackHandle;
    _playbackHandle = null;
    if (handle == null) return;
    final release = _releasePlaybackAccess();
    _accessRelease = release;
    try {
      await release;
    } finally {
      if (identical(_accessRelease, release)) {
        _accessRelease = null;
      }
    }
  }

  Future<void> _releasePlaybackAccess() async {
    try {
      await _userSoundAccess.endPlayback();
    } catch (_) {
      // Scoped access is released best-effort when playback ends.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _playbackGeneration++;
    _sleepTimer?.cancel();
    unawaited(_endPlaybackAccess());
    unawaited(_playerSubscription.cancel());
    unawaited(_positionSubscription.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
