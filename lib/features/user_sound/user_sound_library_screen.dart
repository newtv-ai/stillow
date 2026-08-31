import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/user_sound_store.dart';
import '../../domain/stillow_models.dart';
import '../../l10n/l10n.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class UserSoundLibraryScreen extends StatefulWidget {
  const UserSoundLibraryScreen({
    super.key,
    required this.initialSounds,
    required this.onImport,
    required this.onCancelImport,
    required this.onUsageRequested,
    required this.onUpdate,
    required this.onDelete,
    required this.onReorder,
  });

  final List<UserSound> initialSounds;
  final Future<List<UserSound>> Function(
    void Function(double progress) onProgress,
  )
  onImport;
  final VoidCallback onCancelImport;
  final Future<int> Function() onUsageRequested;
  final Future<UserSound> Function(UserSound sound) onUpdate;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(List<UserSound> sounds) onReorder;

  @override
  State<UserSoundLibraryScreen> createState() => _UserSoundLibraryScreenState();
}

class _UserSoundLibraryScreenState extends State<UserSoundLibraryScreen> {
  late List<UserSound> _sounds;
  bool _importing = false;
  double _progress = 0;
  int? _usageBytes;

  @override
  void initState() {
    super.initState();
    _sounds = [...widget.initialSounds];
    unawaited(_refreshUsage());
  }

  Future<void> _refreshUsage() async {
    try {
      final bytes = await widget.onUsageRequested();
      if (mounted) setState(() => _usageBytes = bytes);
    } catch (_) {
      // The library remains usable when storage usage cannot be read.
    }
  }

  Future<void> _beginImport() async {
    final l10n = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.userSoundsImportTitle),
        content: Text(l10n.userSoundsImportNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.userSoundsChooseFile),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      _importing = true;
      _progress = 0;
    });
    try {
      final imported = await widget.onImport((progress) {
        if (mounted) setState(() => _progress = progress);
      });
      if (imported.isNotEmpty && mounted) {
        setState(() => _sounds = [..._sounds, ...imported]);
        unawaited(_refreshUsage());
      }
    } on UserSoundStoreException catch (error) {
      if (mounted) _showMessage(_messageForFailure(error.failure));
    } catch (_) {
      if (mounted) _showMessage(context.l10n.userSoundsOperationFailed);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _messageForFailure(UserSoundStoreFailure failure) {
    final l10n = context.l10n;
    return switch (failure) {
      UserSoundStoreFailure.cancelled => l10n.userSoundsImportCancelled,
      UserSoundStoreFailure.unsupportedFormat => l10n.userSoundsUnsupported,
      UserSoundStoreFailure.emptyFile => l10n.userSoundsEmptyFile,
      UserSoundStoreFailure.libraryFull => l10n.userSoundsLibraryFull,
      UserSoundStoreFailure.sourceUnavailable =>
        l10n.userSoundsSourceUnavailable,
      UserSoundStoreFailure.importInProgress => l10n.userSoundsImportInProgress,
      UserSoundStoreFailure.writeFailed => l10n.userSoundsWriteFailed,
      UserSoundStoreFailure.notFound => l10n.userSoundsOperationFailed,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(UserSound sound) async {
    final result = await showModalBottomSheet<UserSound>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StillowColors.surface,
      showDragHandle: true,
      builder: (_) => _UserSoundSettingsSheet(sound: sound),
    );
    if (result == null || !mounted) return;
    try {
      final updated = await widget.onUpdate(result);
      if (!mounted) return;
      setState(() {
        final index = _sounds.indexWhere((entry) => entry.id == updated.id);
        if (index >= 0) _sounds[index] = updated;
      });
      _showMessage(context.l10n.userSoundsSaved);
    } catch (_) {
      if (mounted) _showMessage(context.l10n.userSoundsOperationFailed);
    }
  }

  Future<void> _playFrom(UserSound sound) async {
    Navigator.of(context).pop(sound);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    var destination = newIndex;
    if (oldIndex < destination) destination -= 1;
    final previous = [..._sounds];
    final sounds = [..._sounds];
    final moved = sounds.removeAt(oldIndex);
    sounds.insert(destination, moved);
    setState(() => _sounds = sounds);
    try {
      await widget.onReorder(sounds);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sounds = previous);
      _showMessage(context.l10n.userSoundsOperationFailed);
    }
  }

  Future<void> _delete(UserSound sound) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.userSoundsDeleteTitle),
        content: Text(l10n.userSoundsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.userSoundsDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.onDelete(sound.id);
      if (!mounted) return;
      setState(() {
        _sounds.removeWhere((entry) => entry.id == sound.id);
      });
      unawaited(_refreshUsage());
    } catch (_) {
      if (mounted) _showMessage(context.l10n.userSoundsOperationFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_importing,
      child: Scaffold(
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
                      onPressed: () {
                        if (!_importing) Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.userSoundsTitle,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.userSoundsSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_usageBytes case final bytes?) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.userSoundsUsage(
                                _sounds.length,
                                (bytes / (1024 * 1024)).toStringAsFixed(1),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              if (_importing)
                SliverToBoxAdapter(
                  child: _ImportProgress(
                    progress: _progress,
                    onCancel: widget.onCancelImport,
                  ),
                ),
              if (_importing)
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
              if (_sounds.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: StillowColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: StillowColors.outline),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.audio_file_rounded, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          l10n.userSoundsEmptyTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.userSoundsEmptyBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverReorderableList(
                  itemCount: _sounds.length,
                  // Flutter 3.41 still requires this callback; newer SDKs
                  // preserve it for compatibility while preferring onReorderItem.
                  // ignore: deprecated_member_use
                  onReorder: _reorder,
                  itemBuilder: (context, index) {
                    final sound = _sounds[index];
                    return Padding(
                      key: ValueKey(sound.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UserSoundTile(
                        index: index,
                        sound: sound,
                        onPlay: () => unawaited(_playFrom(sound)),
                        onEdit: () => _edit(sound),
                        onDelete: () => _delete(sound),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (_sounds.isNotEmpty)
                SliverToBoxAdapter(
                  child: FilledButton.tonalIcon(
                    onPressed: _importing
                        ? null
                        : () => unawaited(_playFrom(_sounds.first)),
                    icon: const Icon(Icons.playlist_play_rounded),
                    label: Text(l10n.userSoundsPlayList),
                  ),
                ),
              if (_sounds.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: FilledButton.icon(
                  onPressed: _importing ? null : _beginImport,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.userSoundsAdd),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportProgress extends StatelessWidget {
  const _ImportProgress({required this.progress, required this.onCancel});

  final double progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: StillowColors.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.userSoundsImporting),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: progress <= 0 ? null : progress),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onCancel,
            child: Text(context.l10n.userSoundsCancelImport),
          ),
        ),
      ],
    ),
  );
}

class _UserSoundTile extends StatelessWidget {
  const _UserSoundTile({
    required this.index,
    required this.sound,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final UserSound sound;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: StillowColors.surface,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onPlay,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.drag_handle_rounded),
              ),
            ),
            const Icon(Icons.audio_file_rounded, color: StillowColors.sage),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(context.l10n.userSoundsEdit),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.l10n.userSoundsDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _UserSoundSettingsSheet extends StatefulWidget {
  const _UserSoundSettingsSheet({required this.sound});

  final UserSound sound;

  @override
  State<_UserSoundSettingsSheet> createState() =>
      _UserSoundSettingsSheetState();
}

class _UserSoundSettingsSheetState extends State<_UserSoundSettingsSheet> {
  late final TextEditingController _titleController;
  late bool _loop;
  late bool _attenuate;
  late int? _timer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sound.title);
    _loop = widget.sound.loop;
    _attenuate = widget.sound.attenuateLoops;
    _timer = widget.sound.defaultTimerMinutes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      widget.sound.copyWith(
        title: title,
        loop: _loop,
        attenuateLoops: _loop && _attenuate,
        defaultTimerMinutes: _timer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.userSoundsEdit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              maxLength: 80,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.userSoundsRename),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _loop,
              title: Text(l10n.userSoundsLoop),
              subtitle: Text(l10n.userSoundsLoopBody),
              onChanged: (value) => setState(() => _loop = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _loop && _attenuate,
              title: Text(l10n.userSoundsAttenuate),
              subtitle: Text(l10n.userSoundsAttenuateBody),
              onChanged: _loop
                  ? (value) => setState(() => _attenuate = value)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(l10n.userSoundsDefaultTimer),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in const <int?>[15, 30, 45, 60, null])
                  ChoiceChip(
                    selected: _timer == minutes,
                    label: Text(
                      minutes == null
                          ? l10n.userSoundsNoDefaultTimer
                          : l10n.minutesLabel(minutes),
                    ),
                    onSelected: (_) => setState(() => _timer = minutes),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _titleController.text.trim().isEmpty ? null : _save,
                child: Text(l10n.userSoundsSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
