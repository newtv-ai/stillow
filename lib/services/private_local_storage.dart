import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

typedef PrivateDirectoryProvider = Future<Directory> Function();

final class PrivateLocalStorage {
  PrivateLocalStorage._();

  static const _backupChannel = MethodChannel(
    'com.stillow.stillow/private_storage',
  );
  static Future<Directory>? _directoryFuture;

  static Future<Directory> directory() =>
      _directoryFuture ??= _prepareDirectory();

  static Future<Directory> _prepareDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      '${support.path}${Platform.pathSeparator}stillow_private',
    );
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    if (Platform.isIOS) {
      await _backupChannel.invokeMethod<void>('excludeFromBackup', {
        'path': directory.path,
      });
    }
    return directory;
  }
}

final class PrivateJsonFile {
  PrivateJsonFile(this.fileName, {PrivateDirectoryProvider? directoryProvider})
    : _directoryProvider = directoryProvider ?? PrivateLocalStorage.directory;

  final String fileName;
  final PrivateDirectoryProvider _directoryProvider;
  Future<void> _pendingWrite = Future.value();

  Future<Object?> read() async {
    final file = await _file();
    final backup = File('${file.path}.backup');
    for (final candidate in [file, backup]) {
      if (!candidate.existsSync()) continue;
      try {
        return jsonDecode(await candidate.readAsString());
      } on FormatException {
        continue;
      } on FileSystemException {
        continue;
      }
    }
    return null;
  }

  Future<void> write(Object? value) {
    final operation = _pendingWrite.then((_) => _writeNow(value));
    _pendingWrite = operation.catchError((_) {});
    return operation;
  }

  Future<void> _writeNow(Object? value) async {
    final file = await _file();
    final temporary = File('${file.path}.partial');
    final backup = File('${file.path}.backup');
    if (temporary.existsSync()) await temporary.delete();
    await temporary.writeAsString(jsonEncode(value), flush: true);

    if (backup.existsSync()) await backup.delete();
    if (file.existsSync()) await file.rename(backup.path);
    try {
      await temporary.rename(file.path);
      if (backup.existsSync()) await backup.delete();
    } catch (_) {
      if (!file.existsSync() && backup.existsSync()) {
        await backup.rename(file.path);
      }
      rethrow;
    } finally {
      if (temporary.existsSync()) await temporary.delete();
    }
  }

  Future<File> _file() async {
    final directory = await _directoryProvider();
    if (!directory.existsSync()) await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }
}
