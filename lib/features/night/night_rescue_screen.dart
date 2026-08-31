import 'package:flutter/material.dart';

import '../../data/content_catalog.dart';
import '../../domain/sleep_history.dart';
import '../../domain/stillow_models.dart';
import '../../l10n/l10n.dart';
import '../../services/offline_audio_store.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';
import '../player/player_screen.dart';

class NightRescueScreen extends StatefulWidget {
  const NightRescueScreen({
    super.key,
    required this.profile,
    required this.catalog,
    required this.region,
    required this.offlineAudioStore,
    required this.userSounds,
    required this.onNightPresetChanged,
    required this.onPlaybackStarted,
    required this.onSessionFinished,
  });

  final UserProfile profile;
  final ContentCatalog catalog;
  final ContentRegion region;
  final OfflineAudioStore offlineAudioStore;
  final List<UserSound> userSounds;
  final Future<void> Function(GuidedSession session) onNightPresetChanged;
  final Future<void> Function(PlaybackItem item, SleepUseContext context)
  onPlaybackStarted;
  final Future<void> Function(AppSleepSessionRecord record) onSessionFinished;

  @override
  State<NightRescueScreen> createState() => _NightRescueScreenState();
}

class _NightRescueScreenState extends State<NightRescueScreen> {
  PlaybackItem? _item;
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _item ??= _initialItem();
  }

  PlaybackItem _userItem(UserSound sound) {
    final l10n = context.l10n;
    return PlaybackItem.fromUserSound(
      sound,
      subtitle: l10n.userSoundLocalSubtitle,
      shortLabel: l10n.userSoundLocalShortLabel,
      creatorLabel: l10n.userSoundLocalCreator,
    );
  }

  PlaybackItem _initialItem() {
    final preset = widget.catalog.findById(widget.profile.nightPresetSessionId);
    if (preset != null &&
        preset.isPlaybackEligible &&
        preset.regions.contains(widget.region) &&
        preset.kind != SessionKind.lecture &&
        preset.tags.contains('night_awake')) {
      return PlaybackItem.fromGuidedSession(preset);
    }
    return PlaybackItem.fromGuidedSession(
      widget.catalog.recommendNightRescue(widget.profile, widget.region),
    );
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
    final selected = await Navigator.of(context).push<PlaybackItem>(
      MaterialPageRoute<PlaybackItem>(
        builder: (_) => _NightPresetPickerScreen(
          userSounds: widget.userSounds,
          sessions: sessions,
          userItemBuilder: _userItem,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _item = selected);
    final session = selected.guidedSession;
    if (session != null) {
      await widget.onNightPresetChanged(session);
    }
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final selected = _item!;
      final session = selected.guidedSession;
      final fallback = session == null
          ? null
          : widget.catalog.offlineFallbackFor(session, widget.region);
      final playable = session == null
          ? selected
          : PlaybackItem.fromGuidedSession(
              await widget.offlineAudioStore.resolve(session),
            );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PlayerScreen(
            item: playable,
            playlist: selected.userSound == null
                ? const []
                : [for (final sound in widget.userSounds) _userItem(sound)],
            onPlaybackStarted: widget.onPlaybackStarted,
            onSessionFinished: widget.onSessionFinished,
            nightMode: true,
            autoStart: true,
            defaultSleepTimer: selected.userSound == null
                ? const Duration(minutes: 30)
                : selected.userSound!.defaultTimerMinutes == null
                ? null
                : Duration(minutes: selected.userSound!.defaultTimerMinutes!),
            fallbackItem: fallback == null
                ? null
                : PlaybackItem.fromGuidedSession(fallback),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.nightStartFailed)));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: StillowBackdrop(
        showGlow: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 640;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: QuietIconButton(
                        icon: Icons.close_rounded,
                        tooltip: l10n.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(height: compact ? 16 : 36),
                    AmbientOrb(
                      active: true,
                      size: compact ? 132 : 235,
                      icon: Icons.nights_stay_outlined,
                    ),
                    SizedBox(height: compact ? 16 : 40),
                    Text(
                      l10n.nightAwakeHeading,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.nightAwakeBody,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: StillowColors.linenMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.nightReady(_item!.title),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _starting ? null : _choosePreset,
                      child: Text(l10n.nightChangePreset),
                    ),
                    SizedBox(height: compact ? 16 : 28),
                    FilledButton(
                      onPressed: _starting ? null : _start,
                      child: _starting
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.nightStart),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.nightPhysicalNeeds,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NightPresetPickerScreen extends StatelessWidget {
  const _NightPresetPickerScreen({
    required this.userSounds,
    required this.sessions,
    required this.userItemBuilder,
  });

  final List<UserSound> userSounds;
  final List<GuidedSession> sessions;
  final PlaybackItem Function(UserSound sound) userItemBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: StillowBackdrop(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Row(
                children: [
                  QuietIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: l10n.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.nightPresetLibraryTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.nightPresetLibrarySubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (userSounds.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionTitle(l10n.nightPresetPersonalTitle),
              ),
              SliverList.separated(
                itemCount: userSounds.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final sound = userSounds[index];
                  return _PresetTile(
                    icon: Icons.audio_file_rounded,
                    title: sound.title,
                    onTap: () =>
                        Navigator.of(context).pop(userItemBuilder(sound)),
                  );
                },
              ),
            ],
            SliverToBoxAdapter(
              child: _SectionTitle(l10n.nightPresetBuiltInTitle),
            ),
            SliverList.separated(
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _PresetTile(
                  icon: session.icon,
                  title: session.title,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(PlaybackItem.fromGuidedSession(session)),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: StillowColors.surface,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: StillowColors.sage),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_rounded, size: 19),
    ),
  );
}
