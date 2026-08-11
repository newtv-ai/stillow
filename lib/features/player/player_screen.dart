import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/stillow_models.dart';
import '../../services/remote_audio_controller.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.session,
    required this.onSessionStarted,
    this.nightMode = false,
    this.autoStart = false,
    this.fallbackSession,
  });

  final GuidedSession session;
  final Future<void> Function(GuidedSession session) onSessionStarted;
  final bool nightMode;
  final bool autoStart;
  final GuidedSession? fallbackSession;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final RemoteAudioController _controller;
  late GuidedSession _activeSession;
  bool _recorded = false;
  bool _openingPlatform = false;
  bool _platformOpened = false;
  String? _platformError;

  @override
  void initState() {
    super.initState();
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
    if (_controller.status == PlaybackStatus.playing && !_recorded) {
      unawaited(_recordStart());
    }
    if (mounted) setState(() {});
  }

  Future<void> _recordStart() async {
    if (_recorded) return;
    _recorded = true;
    await widget.onSessionStarted(_activeSession);
  }

  Future<void> _start() async {
    if (_activeSession.isInAppAudio) {
      await _controller.start(_activeSession);
      return;
    }
    await _openPlatform();
  }

  Future<void> _openPlatform() async {
    if (_openingPlatform) return;
    setState(() {
      _openingPlatform = true;
      _platformError = null;
    });

    var opened = await launchUrl(
      _activeSession.playbackUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      opened = await launchUrl(_activeSession.playbackUrl);
    }

    if (opened) {
      unawaited(_recordStart());
    }
    if (!mounted) return;
    setState(() {
      _openingPlatform = false;
      _platformOpened = opened;
      _platformError = opened ? null : '暂时没能打开平台，可以稍后再试。';
    });
  }

  Future<void> _toggle() async {
    if (!_activeSession.isInAppAudio) {
      await _openPlatform();
      return;
    }

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

  Future<void> _openSource() async {
    await launchUrl(
      _activeSession.sourcePage,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _close() async {
    await _controller.stop();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _useFallback() async {
    final fallback = widget.fallbackSession;
    if (fallback == null) return;
    setState(() {
      _activeSession = fallback;
      _recorded = false;
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
    _controller.removeListener(_refresh);
    _controller.dispose();
    if (widget.nightMode) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInAppAudio = _activeSession.isInAppAudio;
    final isComplete =
        isInAppAudio && _controller.status == PlaybackStatus.complete;
    final isPlaying = isInAppAudio && _controller.isPlaying;
    final isLoading = isInAppAudio
        ? _controller.status == PlaybackStatus.loading
        : _openingPlatform;
    final errorMessage = isInAppAudio
        ? _controller.errorMessage
        : _platformError;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) unawaited(_controller.stop());
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
                      ? '不用做什么。愿意的话，就让屏幕暗下去。'
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
                              : isInAppAudio
                              ? Icons.play_arrow_rounded
                              : Icons.open_in_new_rounded,
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
                isInAppAudio
                    ? isPlaying
                          ? '正在播放无广告音频'
                          : '轻触播放'
                    : _platformOpened
                    ? '已转到 ${_activeSession.providerLabel}，轻触可再次打开'
                    : '在 ${_activeSession.providerLabel} 官方页面播放',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (isInAppAudio)
                TextButton.icon(
                  onPressed: _chooseSleepTimer,
                  icon: const Icon(Icons.bedtime_outlined, size: 17),
                  label: Text(
                    _controller.sleepTimerEndsAt == null ? '设置淡出时间' : '已设置定时淡出',
                  ),
                ),
              TextButton.icon(
                onPressed: _openSource,
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
