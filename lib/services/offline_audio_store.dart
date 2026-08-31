import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/stillow_models.dart';
import 'private_local_storage.dart';

typedef DownloadProgress = void Function(double? progress);
typedef OfflineDirectoryProvider = Future<Directory> Function();

enum OfflineAudioError { cancelled, quotaExceeded, timeout, other }

class OfflineAudioStore {
  OfflineAudioStore({
    http.Client? client,
    OfflineDirectoryProvider? directoryProvider,
    int maxDownloadBytes = 80 * 1024 * 1024,
    int maxTotalBytes = 512 * 1024 * 1024,
    Duration requestTimeout = const Duration(seconds: 20),
    Duration idleTimeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _directoryProvider = directoryProvider ?? PrivateLocalStorage.directory,
       _maxDownloadBytes = maxDownloadBytes,
       _maxTotalBytes = maxTotalBytes,
       _requestTimeout = requestTimeout,
       _idleTimeout = idleTimeout;

  final http.Client _client;
  final bool _ownsClient;
  final OfflineDirectoryProvider _directoryProvider;
  final int _maxDownloadBytes;
  final int _maxTotalBytes;
  final Duration _requestTimeout;
  final Duration _idleTimeout;
  Future<Directory>? _audioDirectoryFuture;
  final Map<String, Completer<void>> _cancels = {};

  static const _maxRedirects = 5;
  static const _redirectStatusCodes = {301, 302, 303, 307, 308};

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

  Future<int> usageBytes() async {
    final directory = await _audioDirectory();
    if (!directory.existsSync()) return 0;
    var total = 0;
    await for (final entity in directory.list()) {
      if (entity is File) total += entity.lengthSync();
    }
    return total;
  }

  void cancelDownload(String sessionId) {
    final cancel = _cancels[sessionId];
    if (cancel != null && !cancel.isCompleted) {
      cancel.complete();
    }
  }

  Future<File> download(
    GuidedSession session, {
    DownloadProgress? onProgress,
  }) async {
    if (session.playbackType != PlaybackType.directAudio) {
      throw ArgumentError('只有在线直连音频需要下载');
    }
    if (!_isHttpsUrl(session.playbackUrl)) {
      throw const OfflineAudioException('只允许通过 HTTPS 下载音频');
    }

    final existing = await downloadedFile(session);
    if (existing != null) {
      onProgress?.call(1);
      return existing;
    }

    final usedBytes = await usageBytes();
    if (usedBytes >= _maxTotalBytes) {
      throw const OfflineAudioException(
        '离线音频占用空间已满',
        error: OfflineAudioError.quotaExceeded,
      );
    }

    final target = await _fileFor(session);
    final partial = File('${target.path}.partial');
    if (partial.existsSync()) await partial.delete();

    final cancelled = Completer<void>();
    _cancels[session.id] = cancelled;

    try {
      final response = await _sendWithHttpsRedirects(
        session.playbackUrl,
        cancelled: cancelled,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OfflineAudioException('下载返回 ${response.statusCode}');
      }

      final contentType = response.headers['content-type']
          ?.split(';')
          .first
          .trim()
          .toLowerCase();
      if (contentType != null &&
          contentType.isNotEmpty &&
          !contentType.startsWith('audio/') &&
          contentType != 'application/octet-stream' &&
          contentType != 'binary/octet-stream') {
        throw OfflineAudioException('下载内容不是音频：$contentType');
      }

      final expectedBytes = response.contentLength;
      if (expectedBytes != null && expectedBytes > _maxDownloadBytes) {
        throw OfflineAudioException(
          '音频文件过大（最多 ${_maxDownloadBytes ~/ (1024 * 1024)} MB）',
        );
      }
      if (expectedBytes != null && usedBytes + expectedBytes > _maxTotalBytes) {
        throw const OfflineAudioException(
          '离线音频占用空间已满',
          error: OfflineAudioError.quotaExceeded,
        );
      }

      var receivedBytes = 0;
      final sink = partial.openWrite();
      try {
        await _awaitOrCancel(
          response.stream.timeout(_idleTimeout).forEach((chunk) {
            if (cancelled.isCompleted) {
              throw const OfflineAudioException(
                '下载已取消',
                error: OfflineAudioError.cancelled,
              );
            }
            receivedBytes += chunk.length;
            if (receivedBytes > _maxDownloadBytes) {
              throw OfflineAudioException(
                '音频文件超过 ${_maxDownloadBytes ~/ (1024 * 1024)} MB 限制',
              );
            }
            if (usedBytes + receivedBytes > _maxTotalBytes) {
              throw const OfflineAudioException(
                '离线音频占用空间已满',
                error: OfflineAudioError.quotaExceeded,
              );
            }
            onProgress?.call(
              expectedBytes == null || expectedBytes == 0
                  ? null
                  : (receivedBytes / expectedBytes).clamp(0, 1),
            );
            sink.add(chunk);
          }),
          cancelled,
        );
        await sink.close();
      } catch (_) {
        await sink.close();
        rethrow;
      }
      if (!partial.existsSync() || partial.lengthSync() == 0) {
        throw const OfflineAudioException('下载文件为空');
      }
      await partial.rename(target.path);
      onProgress?.call(1);
      return target;
    } catch (error) {
      if (partial.existsSync()) await partial.delete();
      if (error is TimeoutException) {
        throw const OfflineAudioException(
          '下载超时',
          error: OfflineAudioError.timeout,
        );
      }
      rethrow;
    } finally {
      _cancels.remove(session.id);
    }
  }

  Future<http.StreamedResponse> _sendWithHttpsRedirects(
    Uri initialUrl, {
    required Completer<void> cancelled,
  }) async {
    var currentUrl = initialUrl;
    for (var redirectCount = 0; ; redirectCount++) {
      if (!_isHttpsUrl(currentUrl)) {
        throw const OfflineAudioException('音频下载跳转只允许使用 HTTPS');
      }

      final request = http.Request('GET', currentUrl)..followRedirects = false;
      final response = await _awaitOrCancel(
        _client.send(request).timeout(_requestTimeout),
        cancelled,
      );
      if (!_redirectStatusCodes.contains(response.statusCode)) {
        return response;
      }

      await response.stream.drain<void>();
      if (redirectCount >= _maxRedirects) {
        throw const OfflineAudioException('音频下载跳转次数过多');
      }

      final location = response.headers['location'];
      if (location == null || location.trim().isEmpty) {
        throw const OfflineAudioException('音频下载跳转缺少目标地址');
      }

      late final Uri nextUrl;
      try {
        nextUrl = currentUrl.resolve(location.trim());
      } on FormatException {
        throw const OfflineAudioException('音频下载跳转地址无效');
      }
      if (!_isHttpsUrl(nextUrl)) {
        throw const OfflineAudioException('音频下载跳转只允许使用 HTTPS');
      }
      currentUrl = nextUrl;
    }
  }

  Future<T> _awaitOrCancel<T>(Future<T> future, Completer<void> cancelled) {
    if (cancelled.isCompleted) {
      throw const OfflineAudioException(
        '下载已取消',
        error: OfflineAudioError.cancelled,
      );
    }
    return Future.any([
      future,
      cancelled.future.then(
        (_) => throw const OfflineAudioException(
          '下载已取消',
          error: OfflineAudioError.cancelled,
        ),
      ),
    ]);
  }

  static bool _isHttpsUrl(Uri url) =>
      url.scheme.toLowerCase() == 'https' &&
      url.hasAuthority &&
      url.host.isNotEmpty;

  Future<void> delete(GuidedSession session) async {
    if (session.playbackType != PlaybackType.directAudio) return;
    cancelDownload(session.id);
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
    for (final cancel in _cancels.values) {
      if (!cancel.isCompleted) cancel.complete();
    }
    _cancels.clear();
    if (_ownsClient) _client.close();
  }
}

class OfflineAudioException implements Exception {
  const OfflineAudioException(
    this.message, {
    this.error = OfflineAudioError.other,
  });

  final String message;
  final OfflineAudioError error;

  @override
  String toString() => message;
}
