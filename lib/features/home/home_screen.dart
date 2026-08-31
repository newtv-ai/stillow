import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/content_catalog.dart';
import '../../data/sleep_history_store.dart';
import '../../domain/sleep_history.dart';
import '../../domain/stillow_models.dart';
import '../../l10n/l10n.dart';
import '../../services/offline_audio_store.dart';
import '../../services/sleep_health_gateway.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';
import '../night/night_rescue_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../history/sleep_history_screen.dart';
import '../morning/morning_review_screen.dart';
import '../player/player_screen.dart';
import '../privacy/data_privacy_screen.dart';
import '../session/session_library_screen.dart';
import '../session/tonight_state_screen.dart';
import '../support/sleep_support_review_screen.dart';
import '../user_sound/user_sound_library_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.profile,
    required this.catalog,
    required this.region,
    required this.offlineAudioStore,
    required this.userSounds,
    required this.onPlaybackStarted,
    required this.onFeedback,
    required this.onFavoriteChanged,
    required this.onRegionPreferenceChanged,
    required this.onAppLanguagePreferenceChanged,
    required this.onAudioLanguagePreferenceChanged,
    required this.onNightPresetChanged,
    required this.onUserSoundImport,
    required this.onUserSoundImportCancelled,
    required this.onUserSoundUsageRequested,
    required this.onUserSoundChanged,
    required this.onUserSoundDeleted,
    required this.onUserSoundsReordered,
    required this.onProfileChanged,
    required this.onSessionFinished,
    required this.onMorningFeeling,
    required this.sleepHistoryStore,
    required this.sleepHealthGateway,
  });

  final UserProfile profile;
  final ContentCatalog catalog;
  final ContentRegion region;
  final OfflineAudioStore offlineAudioStore;
  final List<UserSound> userSounds;
  final Future<void> Function(PlaybackItem item, SleepUseContext context)
  onPlaybackStarted;
  final Future<void> Function(SessionFeedback feedback) onFeedback;
  final Future<void> Function(String sessionId) onFavoriteChanged;
  final Future<void> Function(RegionPreference preference)
  onRegionPreferenceChanged;
  final Future<void> Function(AppLanguagePreference preference)
  onAppLanguagePreferenceChanged;
  final Future<void> Function(AudioLanguagePreference preference)
  onAudioLanguagePreferenceChanged;
  final Future<void> Function(GuidedSession session) onNightPresetChanged;
  final Future<List<UserSound>> Function(
    void Function(double progress) onProgress,
  )
  onUserSoundImport;
  final VoidCallback onUserSoundImportCancelled;
  final Future<int> Function() onUserSoundUsageRequested;
  final Future<UserSound> Function(UserSound sound) onUserSoundChanged;
  final Future<void> Function(String id) onUserSoundDeleted;
  final Future<void> Function(List<UserSound> sounds) onUserSoundsReordered;
  final Future<void> Function(UserProfile profile) onProfileChanged;
  final Future<void> Function(AppSleepSessionRecord record) onSessionFinished;
  final Future<void> Function(MorningFeeling feeling) onMorningFeeling;
  final SleepHistoryStore sleepHistoryStore;
  final SleepHealthGateway sleepHealthGateway;

  PlaybackItem _userItem(BuildContext context, UserSound sound) {
    final l10n = context.l10n;
    return PlaybackItem.fromUserSound(
      sound,
      subtitle: l10n.userSoundLocalSubtitle,
      shortLabel: l10n.userSoundLocalShortLabel,
      creatorLabel: l10n.userSoundLocalCreator,
    );
  }

  Future<void> _openCatalogPlayer(
    BuildContext context,
    GuidedSession session,
  ) async {
    final playableSession = await offlineAudioStore.resolve(session);
    final fallback = catalog.offlineFallbackFor(session, region);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          item: PlaybackItem.fromGuidedSession(playableSession),
          fallbackItem: fallback == null
              ? null
              : PlaybackItem.fromGuidedSession(fallback),
          onPlaybackStarted: onPlaybackStarted,
          onSessionFinished: onSessionFinished,
        ),
      ),
    );
  }

  Future<void> _openUserPlayer(BuildContext context, UserSound sound) {
    final items = [for (final entry in userSounds) _userItem(context, entry)];
    final index = items.indexWhere((item) => item.userSound?.id == sound.id);
    final start = index < 0 ? _userItem(context, sound) : items[index];
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          item: start,
          playlist: items,
          onPlaybackStarted: onPlaybackStarted,
          onSessionFinished: onSessionFinished,
          onRemoveFromPlaylist: _removeFromPlaylist,
          defaultSleepTimer: sound.defaultTimerMinutes == null
              ? null
              : Duration(minutes: sound.defaultTimerMinutes!),
        ),
      ),
    );
  }

  Future<void> _removeFromPlaylist(PlaybackItem item) async {
    final id = item.userSound?.id;
    if (id == null) return;
    await onUserSoundDeleted(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recommendation = catalog.recommend(profile, region);
    final listStart = userSounds.isEmpty ? null : userSounds.first;
    final recommendationItem = listStart == null
        ? PlaybackItem.fromGuidedSession(recommendation)
        : _userItem(context, listStart);
    final candidateSessions = catalog.candidateSessionsFor(region);
    final studySessions = catalog.studyDrowsyFor(region);

    return Scaffold(
      body: StillowBackdrop(
        padding: EdgeInsets.zero,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 38),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      const StillowWordmark(),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showAbout(context),
                        tooltip: l10n.homeSettingsTooltip,
                        icon: const Icon(Icons.more_horiz_rounded),
                        color: StillowColors.linenMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),
                  Text(
                    l10n.homeGreeting,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.homePrompt,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: StillowColors.linenMuted,
                    ),
                  ),
                  const SizedBox(height: 34),
                  _RecommendationCard(
                    item: recommendationItem,
                    onTap: () => listStart == null
                        ? _openCatalogPlayer(context, recommendation)
                        : _openUserPlayer(context, listStart),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final session = await Navigator.of(context)
                          .push<GuidedSession>(
                            MaterialPageRoute<GuidedSession>(
                              builder: (_) => TonightStateScreen(
                                profile: profile,
                                catalog: catalog,
                                region: region,
                              ),
                            ),
                          );
                      if (session != null && context.mounted) {
                        await _openCatalogPlayer(context, session);
                      }
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(l10n.homeDifferentTonight),
                    style: FilledButton.styleFrom(
                      backgroundColor: StillowColors.surfaceRaised,
                      foregroundColor: StillowColors.linen,
                    ),
                  ),
                  if (profile.pendingFeedback) ...[
                    const SizedBox(height: 28),
                    _FeedbackCard(
                      onFeedback: onFeedback,
                      nightAwake:
                          profile.lastUseContext == SleepUseContext.nightAwake,
                    ),
                  ],
                  if (profile.noHelpCount >= 4) ...[
                    const SizedBox(height: 14),
                    _GentleSupportCard(
                      showProfessional: profile.noHelpCount >= 10,
                    ),
                  ],
                  const SizedBox(height: 36),
                  Text(
                    l10n.homeOtherWays,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  _QuietAction(
                    icon: Icons.audio_file_rounded,
                    title: l10n.userSoundsHomeTitle,
                    subtitle: l10n.userSoundsHomeSubtitle,
                    onTap: () async {
                      final sound = await Navigator.of(context).push<UserSound>(
                        MaterialPageRoute<UserSound>(
                          builder: (_) => UserSoundLibraryScreen(
                            initialSounds: userSounds,
                            onImport: onUserSoundImport,
                            onCancelImport: onUserSoundImportCancelled,
                            onUsageRequested: onUserSoundUsageRequested,
                            onUpdate: onUserSoundChanged,
                            onDelete: onUserSoundDeleted,
                            onReorder: onUserSoundsReordered,
                          ),
                        ),
                      );
                      if (sound != null && context.mounted) {
                        await _openUserPlayer(context, sound);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuietAction(
                    icon: Icons.grid_view_rounded,
                    title: l10n.homeBrowseTitle,
                    subtitle: l10n.homeBrowseSubtitle,
                    onTap: () async {
                      final session = await Navigator.of(context)
                          .push<GuidedSession>(
                            MaterialPageRoute<GuidedSession>(
                              builder: (_) => SessionLibraryScreen(
                                sessions: catalog.sessionsFor(region),
                                favoriteSessionIds: profile.favoriteSessionIds,
                                onFavoriteChanged: onFavoriteChanged,
                                offlineAudioStore: offlineAudioStore,
                              ),
                            ),
                          );
                      if (session != null && context.mounted) {
                        await _openCatalogPlayer(context, session);
                      }
                    },
                  ),
                  if (candidateSessions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _QuietAction(
                      icon: Icons.science_outlined,
                      title: l10n.homeCandidatesTitle,
                      subtitle: l10n.homeCandidatesSubtitle(
                        candidateSessions.length,
                      ),
                      onTap: () async {
                        final session = await Navigator.of(context)
                            .push<GuidedSession>(
                              MaterialPageRoute<GuidedSession>(
                                builder: (_) => SessionLibraryScreen(
                                  sessions: candidateSessions,
                                  favoriteSessionIds:
                                      profile.favoriteSessionIds,
                                  onFavoriteChanged: onFavoriteChanged,
                                  offlineAudioStore: offlineAudioStore,
                                  title: l10n.candidateLibraryTitle,
                                  subtitle: l10n.candidateLibrarySubtitle,
                                ),
                              ),
                            );
                        if (session != null && context.mounted) {
                          await _openCatalogPlayer(context, session);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _QuietAction(
                    icon: Icons.record_voice_over_outlined,
                    title: l10n.homeVoiceTitle,
                    subtitle: l10n.homeVoiceSubtitle,
                    onTap: () async {
                      final session = await Navigator.of(context)
                          .push<GuidedSession>(
                            MaterialPageRoute<GuidedSession>(
                              builder: (_) => SessionLibraryScreen(
                                sessions: catalog.spokenFor(region),
                                favoriteSessionIds: profile.favoriteSessionIds,
                                onFavoriteChanged: onFavoriteChanged,
                                offlineAudioStore: offlineAudioStore,
                                title: l10n.voiceLibraryTitle,
                                subtitle: l10n.voiceLibrarySubtitle,
                              ),
                            ),
                          );
                      if (session != null && context.mounted) {
                        await _openCatalogPlayer(context, session);
                      }
                    },
                  ),
                  if (studySessions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _QuietAction(
                      icon: Icons.menu_book_outlined,
                      title: l10n.homeKnowledgeTitle,
                      subtitle: l10n.homeKnowledgeSubtitle,
                      onTap: () async {
                        final session = await Navigator.of(context)
                            .push<GuidedSession>(
                              MaterialPageRoute<GuidedSession>(
                                builder: (_) => SessionLibraryScreen(
                                  sessions: studySessions,
                                  favoriteSessionIds:
                                      profile.favoriteSessionIds,
                                  onFavoriteChanged: onFavoriteChanged,
                                  offlineAudioStore: offlineAudioStore,
                                  title: l10n.knowledgeLibraryTitle,
                                  subtitle: l10n.knowledgeLibrarySubtitle,
                                ),
                              ),
                            );
                        if (session != null && context.mounted) {
                          await _openCatalogPlayer(context, session);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _QuietAction(
                    icon: Icons.nights_stay_outlined,
                    title: l10n.homeNightAwakeTitle,
                    subtitle: l10n.homeNightAwakeSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NightRescueScreen(
                          profile: profile,
                          catalog: catalog,
                          region: region,
                          offlineAudioStore: offlineAudioStore,
                          userSounds: userSounds,
                          onNightPresetChanged: onNightPresetChanged,
                          onPlaybackStarted: onPlaybackStarted,
                          onSessionFinished: onSessionFinished,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuietAction(
                    icon: Icons.wb_twilight_outlined,
                    title: l10n.homeMorningTitle,
                    subtitle: l10n.homeMorningSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MorningReviewScreen(
                          onFeelingSelected: onMorningFeeling,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _QuietAction(
                    icon: Icons.insights_outlined,
                    title: l10n.homeHistoryTitle,
                    subtitle: l10n.homeHistorySubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SleepHistoryScreen(
                          historyStore: sleepHistoryStore,
                          healthGateway: sleepHealthGateway,
                          catalog: catalog,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  Center(
                    child: Text(
                      l10n.homeFooter,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StillowWordmark(),
                const SizedBox(height: 20),
                Text(
                  l10n.aboutTagline,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.aboutPrototypeNotice,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.interfaceLanguageTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.interfaceLanguageDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preference in AppLanguagePreference.values)
                      ChoiceChip(
                        selected: profile.appLanguagePreference == preference,
                        label: Text(switch (preference) {
                          AppLanguagePreference.system => l10n.languageSystem,
                          AppLanguagePreference.simplifiedChinese =>
                            l10n.languageChinese,
                          AppLanguagePreference.english => l10n.languageEnglish,
                        }),
                        onSelected: (_) async {
                          await onAppLanguagePreferenceChanged(preference);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.audioLanguageTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.audioLanguageDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preference in AudioLanguagePreference.values)
                      ChoiceChip(
                        selected: profile.audioLanguagePreference == preference,
                        label: Text(switch (preference) {
                          AudioLanguagePreference.automatic =>
                            l10n.audioLanguageAutomatic,
                          AudioLanguagePreference.chinese =>
                            l10n.audioLanguageChinese,
                          AudioLanguagePreference.english =>
                            l10n.audioLanguageEnglish,
                          AudioLanguagePreference.any => l10n.audioLanguageAny,
                        }),
                        onSelected: (_) async {
                          await onAudioLanguagePreferenceChanged(preference);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.contentRegionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.contentRegionDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preference in RegionPreference.values)
                      ChoiceChip(
                        selected: profile.regionPreference == preference,
                        label: Text(switch (preference) {
                          RegionPreference.automatic =>
                            region == ContentRegion.mainlandChina
                                ? l10n.contentRegionAutomaticChina
                                : l10n.contentRegionAutomaticInternational,
                          RegionPreference.mainlandChina =>
                            l10n.contentRegionChina,
                          RegionPreference.international =>
                            l10n.contentRegionInternational,
                        }),
                        onSelected: (_) async {
                          await onRegionPreferenceChanged(preference);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (editContext) => OnboardingScreen(
                          initialProfile: profile,
                          hasGuidedRelaxation: catalog.hasGuidedRelaxation,
                          onComplete: (updated) async {
                            await onProfileChanged(updated);
                            if (editContext.mounted) {
                              Navigator.of(editContext).pop();
                            }
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(l10n.adjustPreferences),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            DataPrivacyScreen(historyStore: sleepHistoryStore),
                      ),
                    );
                  },
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: Text(l10n.dataAndPrivacy),
                ),
                TextButton.icon(
                  onPressed: () => _openExternal(
                    context,
                    Uri.parse(
                      'https://github.com/newtv-ai/stillow/releases/latest',
                    ),
                  ),
                  icon: const Icon(Icons.system_update_alt_rounded),
                  label: Text(l10n.viewLatestVersion),
                ),
                TextButton.icon(
                  onPressed: () => _openExternal(
                    context,
                    Uri.parse('https://github.com/newtv-ai/stillow/releases'),
                  ),
                  icon: const Icon(Icons.notes_rounded),
                  label: Text(l10n.releaseNotes),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openExternal(BuildContext context, Uri url) async {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.githubOpenFailed)));
    }
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onTap});

  final PlaybackItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF31443E), Color(0xFF202D2A)],
            ),
            border: Border.all(color: const Color(0xFF445B53)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: StillowColors.background.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(item.icon, color: StillowColors.moon),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 42,
                    color: StillowColors.moon,
                  ),
                ],
              ),
              const SizedBox(height: 38),
              Text(
                l10n.recommendationTryTonight,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 5),
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                item.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietAction extends StatelessWidget {
  const _QuietAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StillowColors.surface.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: StillowColors.sage),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: StillowColors.linenMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GentleSupportCard extends StatelessWidget {
  const _GentleSupportCard({required this.showProfessional});

  final bool showProfessional;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StillowColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: StillowColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showProfessional
                ? l10n.supportProfessionalTitle
                : l10n.supportDifferentPathTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            showProfessional
                ? l10n.supportProfessionalBody
                : l10n.supportDifferentPathBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (showProfessional) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SleepSupportReviewScreen(),
                ),
              ),
              child: Text(l10n.supportLearnMore),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatefulWidget {
  const _FeedbackCard({required this.onFeedback, required this.nightAwake});

  final Future<void> Function(SessionFeedback feedback) onFeedback;
  final bool nightAwake;

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard> {
  bool _saving = false;

  Future<void> _choose(SessionFeedback feedback) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onFeedback(feedback);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.feedbackSaveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StillowColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: StillowColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.feedbackIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            widget.nightAwake
                ? l10n.feedbackNightQuestion
                : l10n.feedbackBedtimeQuestion,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeedbackChip(
                label: widget.nightAwake
                    ? l10n.feedbackNightComfortable
                    : l10n.feedbackComfortable,
                onTap: _saving
                    ? null
                    : () => _choose(SessionFeedback.comfortable),
              ),
              _FeedbackChip(
                label: l10n.feedbackNoDifference,
                onTap: _saving
                    ? null
                    : () => _choose(SessionFeedback.noDifference),
              ),
              _FeedbackChip(
                label: widget.nightAwake
                    ? l10n.feedbackNightNotForMe
                    : l10n.feedbackNotForMe,
                onTap: _saving ? null : () => _choose(SessionFeedback.notForMe),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      backgroundColor: StillowColors.surfaceRaised,
      side: const BorderSide(color: StillowColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    );
  }
}
