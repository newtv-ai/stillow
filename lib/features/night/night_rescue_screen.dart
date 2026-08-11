import 'package:flutter/material.dart';

import '../../data/content_catalog.dart';
import '../../domain/sleep_history.dart';
import '../../domain/stillow_models.dart';
import '../../services/offline_audio_store.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';
import '../player/player_screen.dart';
import '../session/session_library_screen.dart';

class NightRescueScreen extends StatefulWidget {
  const NightRescueScreen({
    super.key,
    required this.profile,
    required this.catalog,
    required this.region,
    required this.offlineAudioStore,
    required this.favoriteSessionIds,
    required this.onFavoriteChanged,
    required this.onNightPresetChanged,
    required this.onSessionStarted,
    required this.onSessionFinished,
  });

  final UserProfile profile;
  final ContentCatalog catalog;
  final ContentRegion region;
  final OfflineAudioStore offlineAudioStore;
  final Set<String> favoriteSessionIds;
  final Future<void> Function(String sessionId) onFavoriteChanged;
  final Future<void> Function(GuidedSession session) onNightPresetChanged;
  final Future<void> Function(GuidedSession session, SleepUseContext context)
  onSessionStarted;
  final Future<void> Function(AppSleepSessionRecord record) onSessionFinished;

  @override
  State<NightRescueScreen> createState() => _NightRescueScreenState();
}

class _NightRescueScreenState extends State<NightRescueScreen> {
  late GuidedSession _session;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _session = _initialSession();
  }

  GuidedSession _initialSession() {
    final preset = widget.catalog.findById(widget.profile.nightPresetSessionId);
    if (preset != null &&
        preset.isPlaybackEligible &&
        preset.regions.contains(widget.region) &&
        preset.kind != SessionKind.lecture &&
        preset.tags.contains('night_awake')) {
      return preset;
    }
    return widget.catalog.recommendNightRescue(widget.profile, widget.region);
  }

  Future<void> _choosePreset() async {
    final sessions = widget.catalog
        .ambientFor(widget.region)
        .where(
          (session) =>
              session.kind != SessionKind.lecture &&
              session.tags.contains('night_awake'),
        )
        .toList(growable: false);
    final selected = await Navigator.of(context).push<GuidedSession>(
      MaterialPageRoute<GuidedSession>(
        builder: (_) => SessionLibraryScreen(
          sessions: sessions,
          favoriteSessionIds: widget.favoriteSessionIds,
          onFavoriteChanged: widget.onFavoriteChanged,
          offlineAudioStore: widget.offlineAudioStore,
          title: '夜里醒来时\n默认放哪一段',
          subtitle: '只选一段此刻不排斥的；以后随时可以换。',
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _session = selected);
    await widget.onNightPresetChanged(selected);
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    final playable = await widget.offlineAudioStore.resolve(_session);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          session: playable,
          onSessionStarted: widget.onSessionStarted,
          onSessionFinished: widget.onSessionFinished,
          nightMode: true,
          autoStart: true,
          defaultSleepTimer: const Duration(minutes: 10),
          fallbackSession: widget.catalog.offlineFallbackFor(
            _session,
            widget.region,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StillowBackdrop(
        showGlow: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: QuietIconButton(
                icon: Icons.close_rounded,
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Spacer(),
            AmbientOrb(
              active: true,
              size: 235,
              icon: Icons.nights_stay_outlined,
            ),
            const SizedBox(height: 40),
            Text('不用看时间。', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              '也不用现在弄清为什么醒来。',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: StillowColors.linenMuted),
            ),
            const SizedBox(height: 18),
            Text(
              '准备播放 · ${_session.title}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: _starting ? null : _choosePreset,
              child: const Text('换一段夜醒预设'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _starting ? null : _start,
              child: _starting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('帮我慢慢安静下来'),
            ),
            const SizedBox(height: 14),
            Text(
              '如果有疼痛、呼吸不适或需要如厕，请先照顾身体。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
