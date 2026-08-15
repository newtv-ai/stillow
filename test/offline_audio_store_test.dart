import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stillow/domain/stillow_models.dart';
import 'package:stillow/services/offline_audio_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'stillow_offline_test_',
    );
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('在线直连音频可下载、离线解析并按单条移除', () async {
    final session = _directAudioSession();
    final client = MockClient((_) async {
      return http.Response.bytes(
        List<int>.generate(32 * 1024, (index) => index % 251),
        200,
        headers: {'content-type': 'audio/mpeg'},
      );
    });
    final store = OfflineAudioStore(
      client: client,
      directoryProvider: () async => temporaryDirectory,
    );
    final progress = <double?>[];

    final file = await store.download(session, onProgress: progress.add);

    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), 32 * 1024);
    expect(progress.last, 1);
    expect(await store.isAvailableOffline(session), isTrue);
    final resolved = await store.resolve(session);
    expect(resolved.localFilePath, file.path);
    expect(resolved.isAvailableOffline, isTrue);

    await store.delete(session);
    expect(file.existsSync(), isFalse);
    expect(await store.isAvailableOffline(session), isFalse);
    store.dispose();
  });

  test('下载失败不会留下半截文件', () async {
    final session = _directAudioSession();
    final store = OfflineAudioStore(
      client: MockClient((_) async => http.Response('unavailable', 503)),
      directoryProvider: () async => temporaryDirectory,
    );

    await expectLater(store.download(session), throwsA(isA<Exception>()));

    final files = temporaryDirectory.listSync(recursive: true);
    expect(files.whereType<File>(), isEmpty);
    store.dispose();
  });

  test('拒绝非 HTTPS 的候选音频', () async {
    final store = OfflineAudioStore(
      client: MockClient((_) async => http.Response('unused', 200)),
      directoryProvider: () async => temporaryDirectory,
    );
    final session = _directAudioSession(
      playbackUrl: Uri.parse('http://example.com/audio.mp3'),
    );

    await expectLater(
      store.download(session),
      throwsA(
        isA<OfflineAudioException>().having(
          (error) => error.message,
          'message',
          contains('HTTPS'),
        ),
      ),
    );
    store.dispose();
  });

  test('拒绝明显不是音频的响应', () async {
    final store = OfflineAudioStore(
      client: MockClient(
        (_) async => http.Response(
          '<html>not audio</html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        ),
      ),
      directoryProvider: () async => temporaryDirectory,
    );

    await expectLater(
      store.download(_directAudioSession()),
      throwsA(
        isA<OfflineAudioException>().having(
          (error) => error.message,
          'message',
          contains('不是音频'),
        ),
      ),
    );
    expect(
      temporaryDirectory.listSync(recursive: true).whereType<File>(),
      isEmpty,
    );
    store.dispose();
  });

  test('限制候选音频下载大小并清理 partial 文件', () async {
    final store = OfflineAudioStore(
      client: MockClient(
        (_) async => http.Response.bytes(
          List<int>.filled(2048, 1),
          200,
          headers: {'content-type': 'audio/mpeg'},
        ),
      ),
      directoryProvider: () async => temporaryDirectory,
      maxDownloadBytes: 1024,
    );

    await expectLater(
      store.download(_directAudioSession()),
      throwsA(isA<OfflineAudioException>()),
    );
    expect(
      temporaryDirectory.listSync(recursive: true).whereType<File>(),
      isEmpty,
    );
    store.dispose();
  });
}

GuidedSession _directAudioSession({Uri? playbackUrl}) => GuidedSession(
  id: 'online-test-audio',
  title: '测试音频',
  subtitle: '测试下载流程',
  shortLabel: '测试',
  kind: SessionKind.narrative,
  tags: const {'narrative'},
  regions: const {ContentRegion.international},
  provider: 'testProvider',
  playbackType: PlaybackType.directAudio,
  playbackUrl: playbackUrl ?? Uri.parse('https://example.com/audio.mp3'),
  adFree: true,
  rightsStatus: 'cc0',
  sourcePage: Uri.parse('https://example.com/source'),
  sourceTitle: 'Test source',
  creator: 'Test creator',
  licenseName: 'CC0 1.0',
  licenseUrl: Uri.parse('https://creativecommons.org/publicdomain/zero/1.0/'),
  loop: false,
  priority: 1,
  enabled: true,
  languageCode: 'en',
  durationSeconds: 30,
);
