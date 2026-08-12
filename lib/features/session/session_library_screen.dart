import 'package:flutter/material.dart';

import '../../domain/stillow_models.dart';
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
    this.title = '换一种\n舒服的方式',
    this.subtitle = '可以按此刻的感觉更换。',
  });

  final List<GuidedSession> sessions;
  final Set<String> favoriteSessionIds;
  final Future<void> Function(String sessionId) onFavoriteChanged;
  final OfflineAudioStore offlineAudioStore;
  final String title;
  final String subtitle;

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
      ).showSnackBar(const SnackBar(content: Text('已经留在这台设备里了。')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这次没下载好，网络方便时再试也可以。')));
    } finally {
      if (mounted) setState(() => _downloadProgress.remove(session.id));
    }
  }

  Future<void> _removeDownload(GuidedSession session) async {
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
              Text('移除这份离线声音？', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '只会清理下载文件，不会取消收藏；以后仍可在线播放或重新下载。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('先留着'),
                  ),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('移除离线文件'),
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
    final visibleSessions = _visibleSessions;
    return Scaffold(
      body: StillowBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuietIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: '返回',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 20),
            Text(widget.title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(widget.subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜声音、作者或主题',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清空',
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in _LibraryFilter.values) ...[
                    ChoiceChip(
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                      label: Text(_filterLabel(filter)),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _checkingOffline
                  ? '正在看看哪些声音已在设备里…'
                  : '${visibleSessions.length} 段可选',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: visibleSessions.isEmpty
                  ? _EmptyLibrary(filter: _filter)
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: visibleSessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = visibleSessions[index];
                        final isDownloaded =
                            session.playbackType == PlaybackType.assetAudio ||
                            _downloadedIds.contains(session.id);
                        return _LibraryCard(
                          session: session,
                          isFavorite: _favorites.contains(session.id),
                          isDownloaded: isDownloaded,
                          downloadProgress: _downloadProgress[session.id],
                          isDownloading: _downloadProgress.containsKey(
                            session.id,
                          ),
                          onTap: () => Navigator.of(context).pop(session),
                          onFavorite: () => _toggleFavorite(session),
                          onOffline:
                              session.playbackType == PlaybackType.assetAudio
                              ? null
                              : isDownloaded
                              ? () => _removeDownload(session)
                              : () => _download(session),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _filterLabel(_LibraryFilter filter) => switch (filter) {
    _LibraryFilter.all => '全部',
    _LibraryFilter.favorites => '收藏',
    _LibraryFilter.ambient => '环境声',
    _LibraryFilter.music => '音乐',
    _LibraryFilter.voice => '人声',
    _LibraryFilter.courses => '科普',
    _LibraryFilter.offline => '已离线',
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
  });

  final GuidedSession session;
  final bool isFavorite;
  final bool isDownloaded;
  final bool isDownloading;
  final double? downloadProgress;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onOffline;

  @override
  Widget build(BuildContext context) {
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
                          const _SmallLabel(
                            icon: Icons.rate_review_outlined,
                            text: '待试听',
                          ),
                        _SmallLabel(
                          icon: isDownloaded
                              ? Icons.offline_pin_outlined
                              : Icons.cloud_outlined,
                          text: isDownloaded ? '离线可用' : '在线',
                        ),
                        _SmallLabel(
                          icon: Icons.translate_rounded,
                          text: _languageLabel(session.languageCode),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: isFavorite ? '取消收藏' : '收藏',
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
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox.square(
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
                          ? '随应用离线提供'
                          : isDownloaded
                          ? '管理离线文件'
                          : '下载到设备',
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

  static String _languageLabel(String code) => switch (code) {
    'zh' => '中文',
    'en' => '英文',
    'zxx' => '无人声',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          filter == _LibraryFilter.favorites
              ? '还没有收藏。听到舒服的声音时，轻点小心形就好。'
              : '这里暂时没有合适的结果，换个词或分类看看。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
