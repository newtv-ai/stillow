import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/sleep_history.dart';
import '../../domain/stillow_models.dart';
import '../../services/remote_audio_controller.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.session,
    required this.onSessionStarted,
    required this.onSessionFinished,
    this.nightMode = false,
    this.autoStart = false,
    this.fallbackSession,
    this.defaultSleepTimer = const Duration(minutes: 30),
  });

  final GuidedSession session;
  final Future<void> Function(GuidedSession session, SleepUseContext context)
  onSessionStarted;
  final Future<void> Function(AppSleepSessionRecord record) onSessionFinished;
  final bool nightMode;
  final bool autoStart;
  final GuidedSession? fallbackSession;
  final Duration? defaultSleepTimer;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  late final RemoteAudioController _controller;
  late GuidedSession _activeSession;
  bool _recorded = false;
  bool _recordFinalized = false;
  bool _settledSessionEnded = false;
  DateTime? _sessionStartedAt;
  String? _sessionRecordId;
  DateTime? _playingSince;
  Duration _listened = Duration.zero;
  Timer? _checkpointTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeSession = widget.session;
    _controller = RemoteAudioController()..addListener(_refresh);

    if (widget.nightMode) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
    }
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _refresh() {
    _updateListeningTime();
    if (_controller.status == PlaybackStatus.playing && !_recorded) {
      unawaited(_recordStart());
    }
    if (_recorded &&
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
        '${_sessionStartedAt!.microsecondsSinceEpoch}-${_activeSession.id}';
    _checkpointTimer?.cancel();
    _checkpointTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_saveSessionCheckpoint());
    });
    await widget.onSessionStarted(
      _activeSession,
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
        sessionId: _activeSession.id,
        sessionTitle: _activeSession.title,
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
    await _controller.start(_activeSession);
    if (_controller.status != PlaybackStatus.error &&
        widget.defaultSleepTimer != null) {
      _controller.setSleepTimer(widget.defaultSleepTimer);
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('这段声音从哪里来', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                _activeSession.sourceTitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 6),
              Text(
                '${_activeSession.creator}\n${_activeSession.licenseName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      _activeSession.sourcePage,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: const Text('查看来源'),
                  ),
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      _activeSession.licenseUrl,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.verified_outlined, size: 17),
                    label: const Text('查看许可'),
                  ),
                ],
              ),
            ],
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
    final fallback = widget.fallbackSession;
    if (fallback == null) return;
    await _finalizeSessionRecord();
    setState(() {
      _activeSession = fallback;
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('让声音慢慢停下', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '最后 30 秒会轻轻淡出。也可以不定时。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in const [15, 30, 45, 60])
                    ActionChip(
                      label: Text('$minutes 分钟'),
                      onPressed: () {
                        _controller.setSleepTimer(Duration(minutes: minutes));
                        Navigator.of(context).pop();
                      },
                    ),
                  ActionChip(
                    label: const Text('不定时'),
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
    );
  }

  @override
  void dispose() {
    unawaited(_finalizeSessionRecord());
    _checkpointTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_refresh);
    _controller.dispose();
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
    final isComplete = _settledSessionEnded;
    final isPlaying = _controller.isPlaying;
    final isLoading = _controller.status == PlaybackStatus.loading;
    final errorMessage = _controller.errorMessage;

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
          child: Column(
            children: [
              Row(
                children: [
                  QuietIconButton(
                    icon: Icons.close_rounded,
                    tooltip: '结束',
                    onPressed: _close,
                  ),
                  const Spacer(),
                  if (!widget.nightMode)
                    Text(
                      _activeSession.shortLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
              const Spacer(),
              AmbientOrb(
                active: isPlaying || isLoading,
                size: widget.nightMode ? 220 : 195,
                icon: _activeSession.icon,
              ),
              const SizedBox(height: 34),
              Text(
                isComplete ? '声音已经慢慢停下' : _activeSession.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  isComplete
                      ? widget.nightMode
                            ? '如果困意还在，就让屏幕暗下去。如果反而更清醒，可以到昏暗、安静的地方坐一会儿，困意回来再上床。'
                            : '不用做什么。愿意的话，就让屏幕暗下去。'
                      : widget.nightMode
                      ? '不需要现在解决任何事情。把音量放得轻一点就好。'
                      : _activeSession.subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: StillowColors.linenMuted,
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (widget.fallbackSession != null &&
                    _activeSession.id != widget.fallbackSession!.id)
                  TextButton.icon(
                    onPressed: _useFallback,
                    icon: const Icon(Icons.offline_bolt_outlined),
                    label: Text('改用离线的「${widget.fallbackSession!.title}」'),
                  ),
              ],
              const Spacer(),
              Semantics(
                button: true,
                label: isPlaying ? '暂停' : '播放',
                child: IconButton.filled(
                  onPressed: isLoading ? null : _toggle,
                  tooltip: isPlaying ? '暂停' : '播放',
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
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
                    disabledBackgroundColor: StillowColors.surfaceRaised,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isPlaying ? '正在播放无广告音频' : '轻触播放',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _chooseSleepTimer,
                icon: const Icon(Icons.bedtime_outlined, size: 17),
                label: Text(
                  _controller.sleepTimerEndsAt == null ? '设置淡出时间' : '已设置定时淡出',
                ),
              ),
              TextButton.icon(
                onPressed: _showCredits,
                icon: const Icon(Icons.info_outline_rounded, size: 17),
                label: Text(
                  '${_activeSession.creator} · ${_activeSession.licenseName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _close,
                child: Text(widget.nightMode ? '安静结束' : '先到这里'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
