import 'package:flutter/material.dart';

import '../../domain/stillow_models.dart';
import '../../l10n/l10n.dart';
import '../../services/offline_audio_store.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

enum _LibraryFilter { all, favorites, ambient, music, voice, courses, offline }

class SessionLibraryScreen extends StatefulWidget {
  const SessionLibraryScreen({
    super.key,
    required this.sessions,
    required this.favoriteSessionIds,
    required this.onFavoriteChanged,
    required this.offlineAudioStore,
    this.title,
    this.subtitle,
  });

  final List<GuidedSession> sessions;
  final Set<String> favoriteSessionIds;
  final Future<void> Function(String sessionId) onFavoriteChanged;
  final OfflineAudioStore offlineAudioStore;
  final String? title;
  final String? subtitle;

  @override
  State<SessionLibraryScreen> createState() => _SessionLibraryScreenState();
}

class _SessionLibraryScreenState extends State<SessionLibraryScreen> {
  final _searchController = TextEditingController();
  late Set<String> _favorites;
  final Set<String> _downloadedIds = {};
  final Map<String, double?> _downloadProgress = {};
  _LibraryFilter _filter = _LibraryFilter.all;
  bool _checkingOffline = true;

  @override
  void initState() {
    super.initState();
    _favorites = Set.from(widget.favoriteSessionIds);
    _searchController.addListener(_refreshSearch);
    _refreshOffline();
  }

  @override
  void didUpdateWidget(covariant SessionLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _favorites = Set.from(widget.favoriteSessionIds);
  }

  void _refreshSearch() => setState(() {});

  Future<void> _refreshOffline() async {
    final downloaded = <String>{};
    for (final session in widget.sessions) {
      if (session.playbackType == PlaybackType.directAudio &&
          await widget.offlineAudioStore.isAvailableOffline(session)) {
        downloaded.add(session.id);
      }
    }
    if (!mounted) return;
    setState(() {
      _downloadedIds
        ..clear()
        ..addAll(downloaded);
      _checkingOffline = false;
    });
  }

  List<GuidedSession> get _visibleSessions {
    final query = _searchController.text.trim().toLowerCase();
    return widget.sessions
        .where((session) {
          final matchesFilter = switch (_filter) {
            _LibraryFilter.all => true,
            _LibraryFilter.favorites => _favorites.contains(session.id),
            _LibraryFilter.ambient => const {
              SessionKind.rain,
              SessionKind.brownNoise,
              SessionKind.ocean,
              SessionKind.forest,
            }.contains(session.kind),
            _LibraryFilter.music => session.kind == SessionKind.music,
            _LibraryFilter.voice => const {
              SessionKind.guidedVoice,
              SessionKind.narrative,
            }.contains(session.kind),
            _LibraryFilter.courses => session.kind == SessionKind.lecture,
            _LibraryFilter.offline =>
              session.playbackType == PlaybackType.assetAudio ||
                  _downloadedIds.contains(session.id),
          };
          if (!matchesFilter || query.isEmpty) return matchesFilter;
          final searchable = [
            session.title,
            session.subtitle,
            session.sourceTitle,
            session.creator,
            session.languageCode,
            ...session.tags,
          ].join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _toggleFavorite(GuidedSession session) async {
    setState(() {
      if (!_favorites.add(session.id)) _favorites.remove(session.id);
    });
    await widget.onFavoriteChanged(session.id);
  }

  Future<void> _download(GuidedSession session) async {
    final l10n = context.l10n;
    if (_downloadProgress.containsKey(session.id)) return;
    setState(() => _downloadProgress[session.id] = 0);
    try {
      await widget.offlineAudioStore.download(
        session,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _downloadProgress[session.id] = progress);
          }
        },
      );
      if (!mounted) return;
      setState(() => _downloadedIds.add(session.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.downloadComplete)));
    } on OfflineAudioException catch (error) {
      if (!mounted) return;
      final message = switch (error.error) {
        OfflineAudioError.cancelled => l10n.downloadCancelled,
        OfflineAudioError.quotaExceeded => l10n.downloadQuotaExceeded,
        OfflineAudioError.timeout => l10n.downloadFailed,
        OfflineAudioError.other => l10n.downloadFailed,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.downloadFailed)));
    } finally {
      if (mounted) setState(() => _downloadProgress.remove(session.id));
    }
  }

  void _cancelDownload(GuidedSession session) {
    widget.offlineAudioStore.cancelDownload(session.id);
  }

  Future<void> _removeDownload(GuidedSession session) async {
    final l10n = context.l10n;
    final confirmed = await showModalBottomSheet<bool>(
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
              Text(
                l10n.removeDownloadTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.removeDownloadBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.keepForNow),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.removeOfflineFile),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    await widget.offlineAudioStore.delete(session);
    if (!mounted) return;
    setState(() => _downloadedIds.remove(session.id));
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visibleSessions = _visibleSessions;
    return Scaffold(
      body: StillowBackdrop(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: QuietIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: l10n.back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Text(
                widget.title ?? l10n.libraryDefaultTitle,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Text(
                widget.subtitle ?? l10n.libraryDefaultSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.librarySearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clear,
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _LibraryFilter.values) ...[
                      ChoiceChip(
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                        label: Text(_filterLabel(l10n, filter)),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Text(
                _checkingOffline
                    ? l10n.libraryCheckingOffline
                    : l10n.libraryAvailableCount(visibleSessions.length),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            if (visibleSessions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyLibrary(filter: _filter),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) return const SizedBox(height: 12);
                  final session = visibleSessions[index ~/ 2];
                  final isDownloaded =
                      session.playbackType == PlaybackType.assetAudio ||
                      _downloadedIds.contains(session.id);
                  final isDownloading = _downloadProgress.containsKey(
                    session.id,
                  );
                  return _LibraryCard(
                    session: session,
                    isFavorite: _favorites.contains(session.id),
                    isDownloaded: isDownloaded,
                    downloadProgress: _downloadProgress[session.id],
                    isDownloading: isDownloading,
                    onTap: () => Navigator.of(context).pop(session),
                    onFavorite: () => _toggleFavorite(session),
                    onCancel: isDownloading
                        ? () => _cancelDownload(session)
                        : null,
                    onOffline: session.playbackType == PlaybackType.assetAudio
                        ? null
                        : isDownloaded
                        ? () => _removeDownload(session)
                        : () => _download(session),
                  );
                }, childCount: visibleSessions.length * 2 - 1),
              ),
          ],
        ),
      ),
    );
  }

  static String _filterLabel(AppLocalizations l10n, _LibraryFilter filter) =>
      switch (filter) {
        _LibraryFilter.all => l10n.filterAll,
        _LibraryFilter.favorites => l10n.filterFavorites,
        _LibraryFilter.ambient => l10n.filterAmbient,
        _LibraryFilter.music => l10n.filterMusic,
        _LibraryFilter.voice => l10n.filterVoice,
        _LibraryFilter.courses => l10n.filterCourses,
        _LibraryFilter.offline => l10n.filterOffline,
      };
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.session,
    required this.isFavorite,
    required this.isDownloaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onTap,
    required this.onFavorite,
    required this.onOffline,
    this.onCancel,
  });

  final GuidedSession session;
  final bool isFavorite;
  final bool isDownloaded;
  final bool isDownloading;
  final double? downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onOffline;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: StillowColors.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: StillowColors.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: StillowColors.backgroundSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(session.icon, color: StillowColors.sage),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      session.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (session.isCandidate)
                          _SmallLabel(
                            icon: Icons.rate_review_outlined,
                            text: l10n.candidateAwaitingReview,
                          ),
                        _SmallLabel(
                          icon: isDownloaded
                              ? Icons.offline_pin_outlined
                              : Icons.cloud_outlined,
                          text: isDownloaded
                              ? l10n.availableOffline
                              : l10n.online,
                        ),
                        _SmallLabel(
                          icon: Icons.translate_rounded,
                          text: _languageLabel(l10n, session.languageCode),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: isFavorite ? l10n.unfavorite : l10n.favorite,
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    color: isFavorite
                        ? StillowColors.moon
                        : StillowColors.linenMuted,
                  ),
                  if (isDownloading)
                    IconButton(
                      tooltip: l10n.cancelDownload,
                      onPressed: onCancel,
                      icon: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          value: downloadProgress,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: session.playbackType == PlaybackType.assetAudio
                          ? l10n.bundledOffline
                          : isDownloaded
                          ? l10n.manageOfflineFile
                          : l10n.downloadToDevice,
                      onPressed: onOffline,
                      icon: Icon(
                        session.playbackType == PlaybackType.assetAudio
                            ? Icons.offline_pin_rounded
                            : isDownloaded
                            ? Icons.delete_outline_rounded
                            : Icons.download_rounded,
                      ),
                      color: StillowColors.linenMuted,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _languageLabel(AppLocalizations l10n, String code) =>
      switch (code) {
        'zh' => l10n.spokenChinese,
        'zh-Hant' => l10n.spokenTraditionalChinese,
        'zh-yue' => l10n.spokenCantonese,
        'en' => l10n.spokenEnglish,
        'zxx' => l10n.noSpokenLanguage,
        _ => code.toUpperCase(),
      };
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: StillowColors.backgroundSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: StillowColors.linenMuted),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.filter});

  final _LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          filter == _LibraryFilter.favorites
              ? l10n.emptyFavorites
              : l10n.emptyLibrary,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
