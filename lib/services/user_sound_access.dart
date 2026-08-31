import 'dart:io';

import 'package:flutter/services.dart';

enum UserSoundAccessCheck { ok, missing, empty }

final class UserSoundPlaybackHandle {
  const UserSoundPlaybackHandle({this.filePath, this.uri});

  final String? filePath;
  final Uri? uri;
}

abstract class UserSoundAccess {
  Future<UserSoundAccessCheck> ensureReadable({
    required String sourcePath,
    String? accessBookmark,
    bool Function()? isCancelled,
  });

  Future<void> persist(String sourcePath);

  Future<String?> refreshBookmark({
    required String sourcePath,
    required String accessBookmark,
  });

  Future<void> release(String sourcePath);

  Future<UserSoundPlaybackHandle> beginPlayback({
    required String sourcePath,
    String? accessBookmark,
  });

  Future<void> endPlayback();
}

final class PluginUserSoundAccess implements UserSoundAccess {
  const PluginUserSoundAccess();

  static const _channel = MethodChannel('com.stillow.stillow/user_sounds');

  @override
  Future<UserSoundAccessCheck> ensureReadable({
    required String sourcePath,
    String? accessBookmark,
    bool Function()? isCancelled,
  }) async {
    if (isCancelled?.call() ?? false) return UserSoundAccessCheck.missing;
    if (sourcePath.isEmpty &&
        (accessBookmark == null || accessBookmark.isEmpty)) {
      return UserSoundAccessCheck.missing;
    }
    if ((accessBookmark != null && accessBookmark.isNotEmpty) ||
        sourcePath.startsWith('content:')) {
      try {
        final size = await _channel.invokeMethod<int>('probe', {
          'uri': sourcePath,
          'bookmark': accessBookmark,
        });
        if (size == null || size < 0) return UserSoundAccessCheck.missing;
        if (size == 0) return UserSoundAccessCheck.empty;
        return UserSoundAccessCheck.ok;
      } on MissingPluginException {
        return UserSoundAccessCheck.missing;
      } on PlatformException {
        return UserSoundAccessCheck.missing;
      }
    }
    return _checkFile(sourcePath);
  }

  @override
  Future<void> persist(String sourcePath) async {
    if (!sourcePath.startsWith('content:')) return;
    await _channel.invokeMethod<void>('persist', {'uri': sourcePath});
  }

  @override
  Future<String?> refreshBookmark({
    required String sourcePath,
    required String accessBookmark,
  }) async {
    if (accessBookmark.isEmpty) return accessBookmark;
    try {
      final refreshed = await _channel.invokeMethod<String>('refreshBookmark', {
        'uri': sourcePath,
        'bookmark': accessBookmark,
      });
      return refreshed == null || refreshed.isEmpty
          ? accessBookmark
          : refreshed;
    } on MissingPluginException {
      return accessBookmark;
    } on PlatformException {
      return accessBookmark;
    }
  }

  @override
  Future<void> release(String sourcePath) async {
    if (!sourcePath.startsWith('content:')) return;
    try {
      await _channel.invokeMethod<void>('release', {'uri': sourcePath});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  @override
  Future<UserSoundPlaybackHandle> beginPlayback({
    required String sourcePath,
    String? accessBookmark,
  }) async {
    if (accessBookmark != null && accessBookmark.isNotEmpty) {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'beginPlayback',
        {'bookmark': accessBookmark, 'uri': sourcePath},
      );
      final path = result?['path'] as String?;
      if (path != null && path.isNotEmpty) {
        return UserSoundPlaybackHandle(filePath: path);
      }
    }
    if (sourcePath.startsWith('content:')) {
      final uri = Uri.tryParse(sourcePath);
      if (uri == null) {
        throw const FormatException('Invalid content URI');
      }
      return UserSoundPlaybackHandle(uri: uri);
    }
    final filePath = _filePath(sourcePath);
    if (filePath.isEmpty) {
      throw const FileSystemException('Missing audio path');
    }
    return UserSoundPlaybackHandle(filePath: filePath);
  }

  @override
  Future<void> endPlayback() async {
    try {
      await _channel.invokeMethod<void>('endPlayback');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static UserSoundAccessCheck _checkFile(String sourcePath) {
    final file = File(_filePath(sourcePath));
    try {
      if (!file.existsSync()) return UserSoundAccessCheck.missing;
      if (file.lengthSync() <= 0) return UserSoundAccessCheck.empty;
      return UserSoundAccessCheck.ok;
    } on FileSystemException {
      return UserSoundAccessCheck.missing;
    }
  }

  static String _filePath(String sourcePath) {
    if (sourcePath.startsWith('file:')) {
      return Uri.parse(sourcePath).toFilePath();
    }
    return sourcePath;
  }
}
