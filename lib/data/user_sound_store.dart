import 'dart:async';
import 'dart:io';

import '../domain/stillow_models.dart';
import '../services/private_local_storage.dart';
import '../services/user_sound_access.dart';
import '../services/user_sound_picker.dart';

enum UserSoundStoreFailure {
  cancelled,
  unsupportedFormat,
  emptyFile,
  libraryFull,
  sourceUnavailable,
  importInProgress,
  notFound,
  writeFailed,
}

final class UserSoundStoreException implements Exception {
  const UserSoundStoreException(this.failure);

  final UserSoundStoreFailure failure;

  @override
  String toString() => 'UserSoundStoreException(${failure.name})';
}

abstract interface class UserSoundStore {
  Future<List<UserSound>> load();

  Future<UserSound> import(
    UserSoundSelection selection, {
    void Function(double progress)? onProgress,
  });

  Future<List<UserSound>> importAll(
    List<UserSoundSelection> selections, {
    void Function(double progress)? onProgress,
  });

  void cancelImport();
  Future<UserSound> update(UserSound sound);
  Future<void> reorder(List<String> ids);
  Future<void> delete(String id);
  Future<int> usageBytes();
}

final class LocalUserSoundStore implements UserSoundStore {
  LocalUserSoundStore({
    PrivateDirectoryProvider? directoryProvider,
    UserSoundAccess? access,
  }) : _rootDirectoryProvider =
           directoryProvider ?? PrivateLocalStorage.directory,
       _access = access ?? const PluginUserSoundAccess(),
       _index = PrivateJsonFile(
         'user_sounds.json',
         directoryProvider: () async {
           final root =
               await (directoryProvider ?? PrivateLocalStorage.directory)();
           final directory = Directory(
             '${root.path}${Platform.pathSeparator}user_sounds',
           );
           if (!directory.existsSync()) await directory.create(recursive: true);
           return directory;
         },
       );

  static const int maxItems = 20;

  final PrivateDirectoryProvider _rootDirectoryProvider;
  final UserSoundAccess _access;
  final PrivateJsonFile _index;
  bool _isImporting = false;
  bool _cancelRequested = false;

  Future<Directory> _directory() async {
    final root = await _rootDirectoryProvider();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}user_sounds',
    );
    if (!directory.existsSync()) await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<List<UserSound>> load() async {
    final directory = await _directory();
    if (!_isImporting) await _removeAbandonedPartialFiles(directory);
    final raw = await _index.read();
    if (raw is! List) return const [];
    final sounds = <UserSound>[];
    var refreshedBookmarks = false;
    for (final entry in raw) {
      final sound = UserSound.tryFromJson(entry);
      if (sound == null) continue;
      final resolved = await _resolveLoaded(sound, directory);
      if (resolved == null) continue;
      sounds.add(resolved);
      refreshedBookmarks =
          refreshedBookmarks || resolved.accessBookmark != sound.accessBookmark;
      if (sounds.length == maxItems) break;
    }
    if (refreshedBookmarks) {
      try {
        await _writeIndex(sounds);
      } catch (_) {
        // The refreshed bookmark still works for this run; retry next launch.
      }
    }
    return List.unmodifiable(sounds);
  }

  Future<UserSound?> _resolveLoaded(
    UserSound sound,
    Directory directory,
  ) async {
    switch (sound.sourceKind) {
      case UserSoundSourceKind.fileCopy:
        if (!_isSafeAudioFileName(sound.relativePath)) return null;
        final file = File(
          '${directory.path}${Platform.pathSeparator}${sound.relativePath}',
        );
        try {
          if (!file.existsSync() || file.lengthSync() <= 0) return null;
        } on FileSystemException {
          return null;
        }
        return sound.copyWith(localFilePath: file.path);
      case UserSoundSourceKind.devicePath:
        final sourcePath = sound.sourcePath;
        if (sourcePath == null || sourcePath.isEmpty) return null;
        final bookmark = sound.accessBookmark;
        if (bookmark != null && bookmark.isNotEmpty) {
          final refreshed = await _access.refreshBookmark(
            sourcePath: sourcePath,
            accessBookmark: bookmark,
          );
          if (refreshed != null && refreshed.isNotEmpty) {
            return sound.copyWith(accessBookmark: refreshed);
          }
          return sound;
        }
        if (sourcePath.startsWith('content:')) {
          return sound;
        }
        final file = File(_filePath(sourcePath));
        try {
          if (!file.existsSync() || file.lengthSync() <= 0) return null;
        } on FileSystemException {
          return null;
        }
        return sound.copyWith(localFilePath: file.path);
    }
  }

  @override
  Future<UserSound> import(
    UserSoundSelection selection, {
    void Function(double progress)? onProgress,
  }) async {
    final imported = await importAll([selection], onProgress: onProgress);
    return imported.single;
  }

  @override
  Future<List<UserSound>> importAll(
    List<UserSoundSelection> selections, {
    void Function(double progress)? onProgress,
  }) async {
    if (_isImporting) {
      throw const UserSoundStoreException(
        UserSoundStoreFailure.importInProgress,
      );
    }
    if (selections.isEmpty) return const [];
    _isImporting = true;
    _cancelRequested = false;
    UserSoundStoreFailure? lastFailure;
    final persistedPaths = <String>[];
    var committed = false;
    try {
      if (_cancelRequested) {
        throw const UserSoundStoreException(UserSoundStoreFailure.cancelled);
      }
      final existing = [...await load()];
      if (existing.length >= maxItems) {
        throw const UserSoundStoreException(UserSoundStoreFailure.libraryFull);
      }
      final imported = <UserSound>[];
      final knownPaths = {
        for (final sound in existing)
          if (sound.sourcePath != null && sound.sourcePath!.isNotEmpty)
            sound.sourcePath!,
      };
      for (var index = 0; index < selections.length; index++) {
        if (_cancelRequested) {
          lastFailure = UserSoundStoreFailure.cancelled;
          break;
        }
        if (existing.length >= maxItems) {
          lastFailure = UserSoundStoreFailure.libraryFull;
          break;
        }
        final selection = selections[index];
        try {
          _validateSelection(selection);
        } on UserSoundStoreException catch (error) {
          lastFailure = error.failure;
          continue;
        }
        if (knownPaths.contains(selection.sourcePath)) continue;
        final check = await _access.ensureReadable(
          sourcePath: selection.sourcePath,
          accessBookmark: selection.accessBookmark,
          isCancelled: () => _cancelRequested,
        );
        if (_cancelRequested) {
          lastFailure = UserSoundStoreFailure.cancelled;
          break;
        }
        switch (check) {
          case UserSoundAccessCheck.missing:
            lastFailure = UserSoundStoreFailure.sourceUnavailable;
            continue;
          case UserSoundAccessCheck.empty:
            lastFailure = UserSoundStoreFailure.emptyFile;
            continue;
          case UserSoundAccessCheck.ok:
            break;
        }
        try {
          await _access.persist(selection.sourcePath);
          if (selection.sourcePath.startsWith('content:')) {
            persistedPaths.add(selection.sourcePath);
          }
        } catch (_) {
          lastFailure = UserSoundStoreFailure.sourceUnavailable;
          continue;
        }
        final sound = UserSound(
          id: _uniqueId(existing),
          title: _titleFromFileName(selection.fileName),
          sourceKind: UserSoundSourceKind.devicePath,
          originalFileName: selection.fileName,
          loop: false,
          attenuateLoops: false,
          createdAt: DateTime.now(),
          sourcePath: selection.sourcePath,
          accessBookmark: selection.accessBookmark,
          localFilePath: _localPathForImport(selection.sourcePath),
        );
        existing.add(sound);
        imported.add(sound);
        knownPaths.add(selection.sourcePath);
        onProgress?.call(((index + 1) / selections.length).clamp(0.0, 1.0));
      }
      if (imported.isEmpty) {
        throw UserSoundStoreException(
          lastFailure ?? UserSoundStoreFailure.sourceUnavailable,
        );
      }
      await _writeIndex(existing);
      committed = true;
      onProgress?.call(1);
      return imported;
    } on UserSoundStoreException {
      rethrow;
    } on FileSystemException {
      throw const UserSoundStoreException(UserSoundStoreFailure.writeFailed);
    } catch (_) {
      throw const UserSoundStoreException(
        UserSoundStoreFailure.sourceUnavailable,
      );
    } finally {
      if (!committed) {
        for (final sourcePath in persistedPaths) {
          try {
            await _access.release(sourcePath);
          } catch (_) {
            // Rollback is best-effort after an index write failure.
          }
        }
      }
      _isImporting = false;
      _cancelRequested = false;
    }
  }

  @override
  void cancelImport() {
    _cancelRequested = true;
  }

  @override
  Future<UserSound> update(UserSound sound) async {
    final sounds = await load();
    final index = sounds.indexWhere((entry) => entry.id == sound.id);
    if (index < 0) {
      throw const UserSoundStoreException(UserSoundStoreFailure.notFound);
    }
    final updated = [...sounds];
    updated[index] = sound.copyWith(localFilePath: sounds[index].localFilePath);
    await _writeIndex(updated);
    return updated[index];
  }

  @override
  Future<void> reorder(List<String> ids) async {
    final sounds = await load();
    if (ids.length != sounds.length) {
      throw const UserSoundStoreException(UserSoundStoreFailure.notFound);
    }
    final byId = {for (final sound in sounds) sound.id: sound};
    final ordered = <UserSound>[];
    for (final id in ids) {
      final sound = byId.remove(id);
      if (sound == null) {
        throw const UserSoundStoreException(UserSoundStoreFailure.notFound);
      }
      ordered.add(sound);
    }
    if (byId.isNotEmpty) {
      throw const UserSoundStoreException(UserSoundStoreFailure.notFound);
    }
    await _writeIndex(ordered);
  }

  @override
  Future<void> delete(String id) async {
    final sounds = await load();
    UserSound? sound;
    for (final entry in sounds) {
      if (entry.id == id) {
        sound = entry;
        break;
      }
    }
    if (sound == null) return;
    final updated = sounds.where((entry) => entry.id != id).toList();
    if (sound.sourceKind == UserSoundSourceKind.fileCopy) {
      final directory = await _directory();
      final path = sound.localFilePath;
      if (path != null && _isInside(directory, path)) {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      }
    } else {
      final sourcePath = sound.sourcePath;
      if (sourcePath != null && sourcePath.startsWith('content:')) {
        await _access.release(sourcePath);
      }
    }
    await _writeIndex(updated);
  }

  @override
  Future<int> usageBytes() async {
    final directory = await _directory();
    var total = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !_isSafeAudioFileName(_baseName(entity.path))) {
        continue;
      }
      try {
        total += await entity.length();
      } on FileSystemException {
        continue;
      }
    }
    return total;
  }

  void _validateSelection(UserSoundSelection selection) {
    if (selection.mimeType?.toLowerCase() == 'audio/aac') {
      throw const UserSoundStoreException(
        UserSoundStoreFailure.unsupportedFormat,
      );
    }
    var extension = _extension(selection.fileName);
    if (extension != 'mp3' && extension != 'm4a') {
      extension = _extension(selection.sourcePath);
    }
    if (extension != 'mp3' && extension != 'm4a') {
      throw const UserSoundStoreException(
        UserSoundStoreFailure.unsupportedFormat,
      );
    }
    if (selection.sourcePath.isEmpty &&
        (selection.accessBookmark == null ||
            selection.accessBookmark!.isEmpty)) {
      throw const UserSoundStoreException(
        UserSoundStoreFailure.sourceUnavailable,
      );
    }
  }

  Future<void> _writeIndex(List<UserSound> sounds) =>
      _index.write(sounds.map((sound) => sound.toJson()).toList());

  String _uniqueId(List<UserSound> existing) {
    final used = {for (final sound in existing) sound.id};
    final base = DateTime.now().microsecondsSinceEpoch;
    for (var suffix = 0; suffix < 1000; suffix++) {
      final id = suffix == 0 ? '$base' : '$base-$suffix';
      if (!used.contains(id)) return id;
    }
    throw const UserSoundStoreException(UserSoundStoreFailure.writeFailed);
  }

  Future<void> _removeAbandonedPartialFiles(Directory directory) async {
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File ||
          !RegExp(
            r'^\d+(?:-\d+)?\.(mp3|m4a)\.partial$',
            caseSensitive: false,
          ).hasMatch(_baseName(entity.path))) {
        continue;
      }
      try {
        await entity.delete();
      } on FileSystemException {
        continue;
      }
    }
  }

  static String? _localPathForImport(String sourcePath) {
    if (sourcePath.startsWith('content:')) return null;
    final path = _filePath(sourcePath);
    return path.isEmpty ? null : path;
  }

  static bool _isInside(Directory directory, String path) {
    final root = Directory(directory.path).uri.resolve('./');
    final file = File(path).uri.resolve('./');
    return file.path.startsWith(root.path);
  }

  static bool _isSafeAudioFileName(String value) => RegExp(
    r'^\d+(?:-\d+)?\.(mp3|m4a)$',
    caseSensitive: false,
  ).hasMatch(value);

  static String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  static String _titleFromFileName(String fileName) {
    final baseName = _baseName(fileName);
    final dot = baseName.lastIndexOf('.');
    final title = (dot > 0 ? baseName.substring(0, dot) : baseName).trim();
    return title.isEmpty ? baseName : title;
  }

  static String _baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.substring(normalized.lastIndexOf('/') + 1);
  }

  static String _filePath(String sourcePath) {
    if (sourcePath.startsWith('file:')) {
      return Uri.parse(sourcePath).toFilePath();
    }
    return sourcePath;
  }
}
