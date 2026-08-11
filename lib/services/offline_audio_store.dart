import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/stillow_models.dart';
import 'private_local_storage.dart';

typedef DownloadProgress = void Function(double? progress);
typedef OfflineDirectoryProvider = Future<Directory> Function();

class OfflineAudioStore {
  OfflineAudioStore({
    http.Client? client,
    OfflineDirectoryProvider? directoryProvider,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _directoryProvider = directoryProvider ?? PrivateLocalStorage.directory;

  final http.Client _client;
  final bool _ownsClient;
  final OfflineDirectoryProvider _directoryProvider;
  Future<Directory>? _audioDirectoryFuture;

  Future<bool> isAvailableOffline(GuidedSession session) async {
    if (session.playbackType == PlaybackType.assetAudio) return true;
    return (await downloadedFile(session)) != null;
  }

  Future<File?> downloadedFile(GuidedSession session) async {
    if (session.playbackType != PlaybackType.directAudio) return null;
    final file = await _fileFor(session);
    return file.existsSync() && file.lengthSync() > 0 ? file : null;
  }

  Future<GuidedSession> resolve(GuidedSession session) async {
    final file = await downloadedFile(session);
    return file == null ? session : session.withLocalFile(file.path);
  }

  Future<File> download(
    GuidedSession session, {
    DownloadProgress? onProgress,
  }) async {
    if (session.playbackType != PlaybackType.directAudio) {
      throw ArgumentError('只有在线直连音频需要下载');
    }

    final existing = await downloadedFile(session);
    if (existing != null) {
      onProgress?.call(1);
      return existing;
    }

    final target = await _fileFor(session);
    final partial = File('${target.path}.partial');
    if (partial.existsSync()) await partial.delete();

    try {
      final request = http.Request('GET', session.playbackUrl);
      final response = await _client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OfflineAudioException('下载返回 ${response.statusCode}');
      }

      final expectedBytes = response.contentLength;
      var receivedBytes = 0;
      final stream = response.stream.map((chunk) {
        receivedBytes += chunk.length;
        onProgress?.call(
          expectedBytes == null || expectedBytes == 0
              ? null
              : (receivedBytes / expectedBytes).clamp(0, 1),
        );
        return chunk;
      });
      await stream.pipe(partial.openWrite());
      if (!partial.existsSync() || partial.lengthSync() == 0) {
        throw const OfflineAudioException('下载文件为空');
      }
      await partial.rename(target.path);
      onProgress?.call(1);
      return target;
    } catch (_) {
      if (partial.existsSync()) await partial.delete();
      rethrow;
    }
  }

  Future<void> delete(GuidedSession session) async {
    if (session.playbackType != PlaybackType.directAudio) return;
    final file = await _fileFor(session);
    if (file.existsSync()) await file.delete();
    final partial = File('${file.path}.partial');
    if (partial.existsSync()) await partial.delete();
  }

  Future<File> _fileFor(GuidedSession session) async {
    final directory = await _audioDirectory();
    final safeId = session.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final extension = _extensionFor(session.playbackUrl.path);
    return File('${directory.path}${Platform.pathSeparator}$safeId$extension');
  }

  Future<Directory> _audioDirectory() =>
      _audioDirectoryFuture ??= _createAudioDirectory();

  Future<Directory> _createAudioDirectory() async {
    final root = await _directoryProvider();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}stillow_audio',
    );
    if (!directory.existsSync()) await directory.create(recursive: true);
    return directory;
  }

  static String _extensionFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.m4a')) return '.m4a';
    if (lower.endsWith('.aac')) return '.aac';
    if (lower.endsWith('.ogg')) return '.ogg';
    if (lower.endsWith('.wav')) return '.wav';
    return '.mp3';
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

class OfflineAudioException implements Exception {
  const OfflineAudioException(this.message);

  final String message;

  @override
  String toString() => message;
}
