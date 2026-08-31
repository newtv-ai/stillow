import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/sleep_history.dart';
import '../../domain/stillow_models.dart';
import '../../l10n/l10n.dart';
import '../../services/remote_audio_controller.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.item,
    required this.onPlaybackStarted,
    required this.onSessionFinished,
    this.playlist = const [],
    this.nightMode = false,
    this.autoStart = false,
    this.fallbackItem,
    this.defaultSleepTimer = const Duration(minutes: 30),
    this.sleepTimerOptions = const [15, 30, 45, 60],
    this.allowNoSleepTimer = true,
    this.playbackController,
    this.onRemoveFromPlaylist,
  });

  final PlaybackItem item;
  final List<PlaybackItem> playlist;
  final Future<void> Function(PlaybackItem item, SleepUseContext context)
  onPlaybackStarted;
  final Future<void> Function(AppSleepSessionRecord record) onSessionFinished;
  final bool nightMode;
  final bool autoStart;
  final PlaybackItem? fallbackItem;
  final Duration? defaultSleepTimer;
  final List<int> sleepTimerOptions;
  final bool allowNoSleepTimer;
  final SleepPlaybackController? playbackController;
  final Future<void> Function(PlaybackItem item)? onRemoveFromPlaylist;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  late final SleepPlaybackController _controller;
  late final bool _ownsController;
  late PlaybackItem _activeItem;
  late List<PlaybackItem> _playlist;
  late int _index;
  bool _recorded = false;
  bool _recordFinalized = false;
  bool _settledSessionEnded = false;
  bool _sleepTimerApplied = false;
  bool _advancing = false;
  DateTime? _sessionStartedAt;
  String? _sessionRecordId;
  DateTime? _playingSince;
  Duration _listened = Duration.zero;
  Timer? _checkpointTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playlist = widget.playlist.isEmpty
        ? [widget.item]
        : List<PlaybackItem>.of(widget.playlist);
    _index = _playlist.indexWhere((entry) => entry.id == widget.item.id);
    if (_index < 0) _index = 0;
    _activeItem = _playlist[_index];
    _ownsController = widget.playbackController == null;
    _controller = widget.playbackController ?? RemoteAudioController();
    _controller.addListener(_refresh);

    if (widget.nightMode) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
    }
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  bool get _hasPrevious => _index > 0;
  bool get _hasNext => _index < _playlist.length - 1;
  bool get _isPlaylist => _playlist.length > 1;

  void _refresh() {
    _updateListeningTime();
    if (_controller.status == PlaybackStatus.playing && !_recorded) {
      unawaited(_recordStart());
    }
    if (!_advancing &&
        _isPlaylist &&
        _hasNext &&
        !_activeItem.loop &&
        (_controller.status == PlaybackStatus.complete ||
            _controller.status == PlaybackStatus.error)) {
      unawaited(_moveTo(_index + 1));
    } else if (_recorded &&
        !_recordFinalized &&
        (_controller.status == PlaybackStatus.complete ||
            _controller.status == PlaybackStatus.idle)) {
      _settledSessionEnded = true;
      unawaited(_finalizeSessionRecord());
    }
    if (mounted) setState(() {});
  }

  Future<void> _recordStart() async {
    if (_recorded) return;
    _recorded = true;
    _recordFinalized = false;
    _sessionStartedAt = DateTime.now();
    _sessionRecordId =
        '${_sessionStartedAt!.microsecondsSinceEpoch}-${_activeItem.id}';
    _checkpointTimer?.cancel();
    _checkpointTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_saveSessionCheckpoint());
    });
    await widget.onPlaybackStarted(
      _activeItem,
      widget.nightMode ? SleepUseContext.nightAwake : SleepUseContext.bedtime,
    );
  }

  void _updateListeningTime() {
    final now = DateTime.now();
    if (_controller.status == PlaybackStatus.playing) {
      _playingSince ??= now;
      return;
    }
    final playingSince = _playingSince;
    if (playingSince == null) return;
    _listened += now.difference(playingSince);
    _playingSince = null;
  }

  Future<void> _finalizeSessionRecord() async {
    if (_recordFinalized || !_recorded || _sessionStartedAt == null) return;
    _recordFinalized = true;
    _checkpointTimer?.cancel();
    _checkpointTimer = null;
    final now = DateTime.now();
    final playingSince = _playingSince;
    if (playingSince != null) {
      _listened += now.difference(playingSince);
      _playingSince = null;
    }
    await _saveSessionCheckpoint(minimumSeconds: 1);
  }

  Future<void> _saveSessionCheckpoint({int minimumSeconds = 0}) async {
    final startedAt = _sessionStartedAt;
    final recordId = _sessionRecordId;
    if (!_recorded || startedAt == null || recordId == null) return;
    var listened = _listened;
    final playingSince = _playingSince;
    if (playingSince != null) {
      listened += DateTime.now().difference(playingSince);
    }
    final seconds = listened.inSeconds < minimumSeconds
        ? minimumSeconds
        : listened.inSeconds;
    if (seconds == 0) return;
    await widget.onSessionFinished(
      AppSleepSessionRecord(
        id: recordId,
        startedAt: startedAt,
        sessionId: _activeItem.id,
        sessionTitle: _activeItem.title,
        context: widget.nightMode
            ? SleepUseContext.nightAwake
            : SleepUseContext.bedtime,
        listenedSeconds: seconds,
      ),
    );
  }

  Future<void> _start() async {
    if (_recordFinalized) {
      _recorded = false;
      _recordFinalized = false;
      _settledSessionEnded = false;
      _sessionStartedAt = null;
      _sessionRecordId = null;
      _playingSince = null;
      _listened = Duration.zero;
    }
    await _controller.start(_activeItem);
    if (_controller.status != PlaybackStatus.error &&
        !_sleepTimerApplied &&
        widget.defaultSleepTimer != null) {
      _controller.setSleepTimer(widget.defaultSleepTimer);
      _sleepTimerApplied = true;
    }
  }

  Future<void> _moveTo(int nextIndex) async {
    if (_advancing || nextIndex < 0 || nextIndex >= _playlist.length) return;
    _advancing = true;
    try {
      await _finalizeSessionRecord();
      if (!mounted) return;
      setState(() {
        _index = nextIndex;
        _activeItem = _playlist[nextIndex];
        _recorded = false;
        _recordFinalized = false;
        _settledSessionEnded = false;
        _sessionStartedAt = null;
        _sessionRecordId = null;
        _playingSince = null;
        _listened = Duration.zero;
      });
      await _start();
    } finally {
      _advancing = false;
    }
  }

  Future<void> _removeAt(int index) async {
    if (_advancing || index < 0 || index >= _playlist.length) return;
    final removed = _playlist[index];
    final wasCurrent = index == _index;
    _advancing = true;
    try {
      if (wasCurrent) await _finalizeSessionRecord();
      await widget.onRemoveFromPlaylist?.call(removed);
      if (!mounted) return;
      final remaining = [..._playlist]..removeAt(index);
      if (remaining.isEmpty) {
        await _close();
        return;
      }
      var nextIndex = _index;
      if (index < _index) {
        nextIndex = _index - 1;
      } else if (wasCurrent) {
        nextIndex = index >= remaining.length ? remaining.length - 1 : index;
      }
      setState(() {
        _playlist = remaining;
        _index = nextIndex;
        _activeItem = remaining[nextIndex];
        if (wasCurrent) {
          _recorded = false;
          _recordFinalized = false;
          _settledSessionEnded = false;
          _sessionStartedAt = null;
          _sessionRecordId = null;
          _playingSince = null;
          _listened = Duration.zero;
        }
      });
      if (wasCurrent) await _start();
    } finally {
      _advancing = false;
    }
  }

  Future<void> _toggle() async {
    switch (_controller.status) {
      case PlaybackStatus.idle:
      case PlaybackStatus.complete:
      case PlaybackStatus.error:
        await _start();
      case PlaybackStatus.playing:
        await _controller.pause();
      case PlaybackStatus.paused:
        await _controller.resume();
      case PlaybackStatus.loading:
        break;
    }
  }

  void _showCredits() {
    final session = _activeItem.guidedSession;
    if (session == null) return;
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.playerCreditsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  session.sourceTitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${session.creator}\n${session.licenseName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        session.sourcePage,
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: Text(l10n.viewSource),
                    ),
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        session.licenseUrl,
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.verified_outlined, size: 17),
                      label: Text(l10n.viewLicense),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _close() async {
    await _finalizeSessionRecord();
    await _controller.stop();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _useFallback() async {
    final fallback = widget.fallbackItem;
    if (fallback == null) return;
    await _finalizeSessionRecord();
    setState(() {
      _activeItem = fallback;
      _recorded = false;
      _recordFinalized = false;
      _settledSessionEnded = false;
      _sessionStartedAt = null;
      _sessionRecordId = null;
      _playingSince = null;
      _listened = Duration.zero;
    });
    await _start();
  }

  void _chooseSleepTimer() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sleepTimerTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.sleepTimerBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutes in widget.sleepTimerOptions)
                      ActionChip(
                        label: Text(l10n.minutesLabel(minutes)),
                        onPressed: () {
                          _controller.setSleepTimer(Duration(minutes: minutes));
                          Navigator.of(context).pop();
                        },
                      ),
                    if (widget.allowNoSleepTimer)
                      ActionChip(
                        label: Text(l10n.noTimer),
                        onPressed: () {
                          _controller.setSleepTimer(null);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_finalizeSessionRecord());
    _checkpointTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_refresh);
    if (_ownsController) {
      _controller.dispose();
    }
    if (widget.nightMode) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_saveSessionCheckpoint());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isComplete = _settledSessionEnded;
    final isPlaying = _controller.isPlaying;
    final isLoading = _controller.status == PlaybackStatus.loading;
    final errorMessage = switch (_controller.failure) {
      PlaybackFailure.loadFailed => l10n.playbackLoadFailed,
      PlaybackFailure.loadInterrupted => l10n.playbackInterrupted,
      PlaybackFailure.unavailable => l10n.playbackUnavailable,
      PlaybackFailure.stoppedRetry => l10n.playbackStoppedRetry,
      PlaybackFailure.stopped => l10n.playbackStopped,
      null => null,
    };

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          unawaited(_finalizeSessionRecord());
          unawaited(_controller.stop());
        }
      },
      child: Scaffold(
        body: StillowBackdrop(
          showGlow: false,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 640;
              final orbSize = compact
                  ? (widget.nightMode ? 132.0 : 112.0)
                  : (widget.nightMode ? 220.0 : 195.0);
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          QuietIconButton(
                            icon: Icons.close_rounded,
                            tooltip: l10n.finish,
                            onPressed: _close,
                          ),
                          if (!widget.nightMode) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _activeItem.shortLabel,
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: compact ? 16 : 36),
                      AmbientOrb(
                        active: isPlaying || isLoading,
                        size: orbSize,
                        icon: _activeItem.icon,
                      ),
                      SizedBox(height: compact ? 16 : 34),
                      Text(
                        isComplete
                            ? l10n.playerCompleteTitle
                            : _activeItem.title,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Text(
                          isComplete
                              ? widget.nightMode
                                    ? l10n.playerNightCompleteBody
                                    : l10n.playerCompleteBody
                              : widget.nightMode
                              ? l10n.playerNightBody
                              : _activeItem.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: StillowColors.linenMuted),
                        ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (widget.fallbackItem != null &&
                            _activeItem.id != widget.fallbackItem!.id)
                          TextButton.icon(
                            onPressed: _useFallback,
                            icon: const Icon(Icons.offline_bolt_outlined),
                            label: Text(
                              l10n.useOfflineFallback(
                                widget.fallbackItem!.title,
                              ),
                            ),
                          ),
                      ],
                      SizedBox(height: compact ? 16 : 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isPlaylist) ...[
                            IconButton(
                              onPressed: !isLoading && _hasPrevious
                                  ? () => unawaited(_moveTo(_index - 1))
                                  : null,
                              tooltip: l10n.userSoundsPrevious,
                              icon: const Icon(Icons.skip_previous_rounded),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Semantics(
                            button: true,
                            label: isPlaying ? l10n.pause : l10n.play,
                            child: IconButton.filled(
                              onPressed: isLoading ? null : _toggle,
                              tooltip: isPlaying ? l10n.pause : l10n.play,
                              icon: isLoading
                                  ? const SizedBox.square(
                                      dimension: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 38,
                                    ),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(76, 76),
                                backgroundColor: StillowColors.moon,
                                foregroundColor: StillowColors.background,
                                disabledBackgroundColor:
                                    StillowColors.surfaceRaised,
                              ),
                            ),
                          ),
                          if (_isPlaylist) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: !isLoading && _hasNext
                                  ? () => unawaited(_moveTo(_index + 1))
                                  : null,
                              tooltip: l10n.userSoundsNext,
                              icon: const Icon(Icons.skip_next_rounded),
                            ),
                          ],
                        ],
                      ),
                      if (_isPlaylist && !isComplete) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.userSoundsPlaylistPosition(
                            _index + 1,
                            _playlist.length,
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        isPlaying
                            ? _activeItem.isCandidate
                                  ? l10n.playingCandidate
                                  : l10n.playingAudio
                            : _activeItem.isCandidate
                            ? l10n.tapToPreview
                            : l10n.tapToPlay,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _chooseSleepTimer,
                        icon: const Icon(Icons.bedtime_outlined, size: 17),
                        label: Text(
                          _controller.sleepTimerEndsAt == null
                              ? l10n.setFadeTimer
                              : l10n.fadeTimerSet,
                        ),
                      ),
                      if (_activeItem.guidedSession != null)
                        TextButton(
                          onPressed: _showCredits,
                          child: Text(
                            '${_activeItem.creator} · ${_activeItem.guidedSession!.licenseName}',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_android_rounded, size: 16),
                              const SizedBox(width: 7),
                              Text(l10n.userSoundLocalBadge),
                            ],
                          ),
                        ),
                      TextButton(
                        onPressed: _close,
                        child: Text(
                          widget.nightMode ? l10n.quietFinish : l10n.stopHere,
                        ),
                      ),
                      if (_isPlaylist && !widget.nightMode) ...[
                        const SizedBox(height: 8),
                        for (var index = 0; index < _playlist.length; index++)
                          _PlaylistRow(
                            item: _playlist[index],
                            selected: index == _index,
                            onTap: isLoading
                                ? null
                                : () => unawaited(_moveTo(index)),
                            onRemove: isLoading
                                ? null
                                : () => unawaited(_removeAt(index)),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final PlaybackItem item;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final color = selected ? StillowColors.sage : StillowColors.linen;
    return Material(
      color: selected ? StillowColors.surfaceRaised : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected ? Icons.graphic_eq_rounded : Icons.audio_file_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.userSoundsRemoveFromList,
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
