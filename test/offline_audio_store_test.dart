import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stillow/data/content_catalog.dart';
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
    final catalog = await ContentCatalog.loadAsset();
    final session = catalog.findById('narrative-selborne-01')!;
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
    final catalog = await ContentCatalog.loadAsset();
    final session = catalog.findById('narrative-selborne-01')!;
    final store = OfflineAudioStore(
      client: MockClient((_) async => http.Response('unavailable', 503)),
      directoryProvider: () async => temporaryDirectory,
    );

    await expectLater(store.download(session), throwsA(isA<Exception>()));

    final files = temporaryDirectory.listSync(recursive: true);
    expect(files.whereType<File>(), isEmpty);
    store.dispose();
  });
}
