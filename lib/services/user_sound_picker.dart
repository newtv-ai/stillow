import 'package:flutter/services.dart';

final class UserSoundSelection {
  const UserSoundSelection({
    required this.fileName,
    required this.sourcePath,
    this.declaredSize = 0,
    this.accessBookmark,
    this.mimeType,
  });

  final String fileName;
  final String sourcePath;
  final int declaredSize;
  final String? accessBookmark;
  final String? mimeType;
}

abstract interface class UserSoundPicker {
  Future<List<UserSoundSelection>?> pick();
}

final class PluginUserSoundPicker implements UserSoundPicker {
  const PluginUserSoundPicker();

  static const _channel = MethodChannel('com.stillow.stillow/user_sounds');

  @override
  Future<List<UserSoundSelection>?> pick() async {
    final result = await _channel.invokeMethod<List<dynamic>>('pick');
    if (result == null || result.isEmpty) return null;
    final selections = <UserSoundSelection>[];
    for (final entry in result) {
      if (entry is! Map) continue;
      final fileName = entry['fileName'];
      final sourcePath = entry['sourcePath'];
      if (fileName is! String ||
          fileName.isEmpty ||
          sourcePath is! String ||
          sourcePath.isEmpty) {
        continue;
      }
      final size = entry['declaredSize'];
      final bookmark = entry['accessBookmark'];
      final mimeType = entry['mimeType'];
      selections.add(
        UserSoundSelection(
          fileName: fileName,
          sourcePath: sourcePath,
          declaredSize: size is num ? size.toInt() : 0,
          accessBookmark: bookmark is String && bookmark.isNotEmpty
              ? bookmark
              : null,
          mimeType: mimeType is String && mimeType.isNotEmpty
              ? mimeType.toLowerCase()
              : null,
        ),
      );
    }
    if (selections.isEmpty) {
      throw StateError('The selected files did not include a usable path.');
    }
    return selections;
  }
}
