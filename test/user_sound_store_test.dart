import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/data/user_sound_store.dart';
import 'package:stillow/domain/stillow_models.dart';
import 'package:stillow/services/user_sound_access.dart';
import 'package:stillow/services/user_sound_picker.dart';

void main() {
  late Directory directory;
  late Directory sourceDirectory;
  late LocalUserSoundStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('stillow-user-sounds-');
    sourceDirectory = await Directory.systemTemp.createTemp(
      'stillow-user-sound-source-',
    );
    store = LocalUserSoundStore(directoryProvider: () async => directory);
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
    if (sourceDirectory.existsSync()) {
      await sourceDirectory.delete(recursive: true);
    }
  });

  test('导入只保存路径，不把音频再复制进 App', () async {
    final original = await _writeSource(sourceDirectory, 'quiet.MP3', [
      1,
      2,
      3,
      4,
    ]);
    final progress = <double>[];
    final sound = await store.import(
      _selection(original),
      onProgress: progress.add,
    );

    expect(sound.title, 'quiet');
    expect(sound.sourceKind, UserSoundSourceKind.devicePath);
    expect(sound.sourcePath, original.path);
    expect(sound.localFilePath, original.path);
    expect(await original.readAsBytes(), [1, 2, 3, 4]);
    expect(progress.last, 1);
    expect(_audioCopies(directory), isEmpty);

    final restored = await LocalUserSoundStore(
      directoryProvider: () async => directory,
    ).load();
    expect(restored, hasLength(1));
    expect(restored.single.id, sound.id);
    expect(restored.single.sourcePath, original.path);
    expect(restored.single.localFilePath, original.path);
  });

  test('损坏索引不会阻止启动', () async {
    final soundsDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}user_sounds',
    );
    await soundsDirectory.create(recursive: true);
    await File(
      '${soundsDirectory.path}${Platform.pathSeparator}user_sounds.json',
    ).writeAsString('{broken');

    expect(await store.load(), isEmpty);
  });

  test('索引字段类型错误时跳过坏记录', () async {
    final soundsDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}user_sounds',
    );
    await soundsDirectory.create(recursive: true);
    await File(
      '${soundsDirectory.path}${Platform.pathSeparator}user_sounds.json',
    ).writeAsString(
      '[{"id":"bad","title":"bad","sourceKind":7,'
      '"relativePath":"7.mp3","originalFileName":"bad.mp3",'
      '"createdAt":123}]',
    );

    expect(await store.load(), isEmpty);
  });

  test('启动读取会清理上次异常退出留下的音频半成品', () async {
    final soundsDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}user_sounds',
    );
    await soundsDirectory.create(recursive: true);
    final partial = File(
      '${soundsDirectory.path}${Platform.pathSeparator}123.mp3.partial',
    );
    await partial.writeAsBytes([1, 2, 3]);

    await store.load();

    expect(partial.existsSync(), isFalse);
  });

  test('旧索引缺少来源和计时字段时按本机文件与 30 分钟迁移', () async {
    final soundsDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}user_sounds',
    );
    await soundsDirectory.create(recursive: true);
    await File(
      '${soundsDirectory.path}${Platform.pathSeparator}42.mp3',
    ).writeAsBytes([1, 2]);
    await File(
      '${soundsDirectory.path}${Platform.pathSeparator}user_sounds.json',
    ).writeAsString(
      '[{"id":"42","title":"old","relativePath":"42.mp3",'
      '"originalFileName":"old.mp3","loop":false,'
      '"attenuateLoops":false,"createdAt":"2026-01-01T00:00:00.000"}]',
    );

    final restored = await store.load();

    expect(restored.single.sourceKind.name, 'fileCopy');
    expect(restored.single.defaultTimerMinutes, 30);
  });

  test('iOS 书签刷新后会更新内存并回写索引', () async {
    final soundsDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}user_sounds',
    );
    await soundsDirectory.create(recursive: true);
    final sound = UserSound(
      id: 'bookmark',
      title: '夜雨',
      sourceKind: UserSoundSourceKind.devicePath,
      sourcePath: '/outside/night-rain.m4a',
      accessBookmark: 'legacy-bookmark',
      originalFileName: 'night-rain.m4a',
      loop: false,
      attenuateLoops: false,
      createdAt: DateTime(2026),
    );
    final index = File(
      '${soundsDirectory.path}${Platform.pathSeparator}user_sounds.json',
    );
    await index.writeAsString(jsonEncode([sound.toJson()]));
    final access = _RecordingAccess(refreshedBookmark: 'scoped-bookmark');
    store = LocalUserSoundStore(
      directoryProvider: () async => directory,
      access: access,
    );

    final restored = await store.load();
    final saved = jsonDecode(await index.readAsString()) as List<dynamic>;

    expect(restored.single.accessBookmark, 'scoped-bookmark');
    expect(
      (saved.single as Map<String, dynamic>)['accessBookmark'],
      'scoped-bookmark',
    );
  });

  test('不支持的格式会在写入索引前拒绝', () async {
    final original = await _writeSource(sourceDirectory, 'sound.wav', [1]);
    await expectLater(
      store.import(_selection(original)),
      throwsA(
        isA<UserSoundStoreException>().having(
          (error) => error.failure,
          'failure',
          UserSoundStoreFailure.unsupportedFormat,
        ),
      ),
    );
    expect(_audioCopies(directory), isEmpty);
  });

  test('伪装成 M4A 的原始 AAC 会在持久化授权前拒绝', () async {
    final access = _RecordingAccess();
    store = LocalUserSoundStore(
      directoryProvider: () async => directory,
      access: access,
    );

    await expectLater(
      store.import(
        const UserSoundSelection(
          fileName: 'raw-aac.m4a',
          sourcePath: 'content://media/raw-aac',
          mimeType: 'audio/aac',
        ),
      ),
      throwsA(
        isA<UserSoundStoreException>().having(
          (error) => error.failure,
          'failure',
          UserSoundStoreFailure.unsupportedFormat,
        ),
      ),
    );

    expect(access.persisted, isEmpty);
    expect(await store.load(), isEmpty);
  });

  test('Android URI 只在校验通过后持久化，跳过项不会占用授权', () async {
    final access = _RecordingAccess();
    store = LocalUserSoundStore(
      directoryProvider: () async => directory,
      access: access,
    );

    final imported = await store.importAll(const [
      UserSoundSelection(
        fileName: 'skip.wav',
        sourcePath: 'content://media/skip',
        mimeType: 'audio/wav',
      ),
      UserSoundSelection(
        fileName: 'keep.mp3',
        sourcePath: 'content://media/keep',
        mimeType: 'audio/mpeg',
      ),
    ]);

    expect(imported.single.sourcePath, 'content://media/keep');
    expect(access.persisted, ['content://media/keep']);
    expect(access.released, isEmpty);

    await expectLater(
      store.import(
        const UserSoundSelection(
          fileName: 'keep.mp3',
          sourcePath: 'content://media/keep',
          mimeType: 'audio/mpeg',
        ),
      ),
      throwsA(isA<UserSoundStoreException>()),
    );
    expect(access.persisted, ['content://media/keep']);
    expect(access.released, isEmpty);
  });

  test('索引提交失败会回滚本次新取得的 Android URI 授权', () async {
    final access = _RecordingAccess();
    final blockedRoot = File(
      '${directory.path}${Platform.pathSeparator}blocked-root',
    );
    await blockedRoot.writeAsString('not a directory');
    var providerCalls = 0;
    store = LocalUserSoundStore(
      directoryProvider: () async {
        providerCalls++;
        return providerCalls < 3 ? directory : Directory(blockedRoot.path);
      },
      access: access,
    );

    await expectLater(
      store.import(
        const UserSoundSelection(
          fileName: 'rollback.mp3',
          sourcePath: 'content://media/rollback',
          mimeType: 'audio/mpeg',
        ),
      ),
      throwsA(
        isA<UserSoundStoreException>().having(
          (error) => error.failure,
          'failure',
          UserSoundStoreFailure.writeFailed,
        ),
      ),
    );

    expect(access.persisted, ['content://media/rollback']);
    expect(access.released, ['content://media/rollback']);
  });

  test('选择器未报大小时仍按原文件加入路径', () async {
    final original = await _writeSource(sourceDirectory, 'unknown-size.mp3', [
      1,
      2,
      3,
      4,
      5,
    ]);
    final sound = await store.import(
      UserSoundSelection(
        fileName: 'unknown-size.mp3',
        sourcePath: original.path,
        declaredSize: 0,
      ),
    );

    expect(sound.sourcePath, original.path);
    expect(await original.readAsBytes(), [1, 2, 3, 4, 5]);
    expect(await store.load(), hasLength(1));
    expect(_audioCopies(directory), isEmpty);
  });

  test('空文件会拒绝且不写索引', () async {
    final original = await _writeSource(sourceDirectory, 'empty.mp3', []);
    await expectLater(
      store.import(_selection(original)),
      throwsA(
        isA<UserSoundStoreException>().having(
          (error) => error.failure,
          'failure',
          UserSoundStoreFailure.emptyFile,
        ),
      ),
    );
    expect(await store.load(), isEmpty);
  });

  test('读取途中取消会停下且不写索引', () async {
    final original = await _writeSource(sourceDirectory, 'rain.m4a', [
      1,
      2,
      3,
      4,
    ]);
    final started = Completer<void>();
    final hanging = _HangingAccess(started);
    store = LocalUserSoundStore(
      directoryProvider: () async => directory,
      access: hanging,
    );
    final importing = store.import(_selection(original));
    await started.future;
    store.cancelImport();
    hanging.releaseHang();

    await expectLater(
      importing,
      throwsA(
        isA<UserSoundStoreException>().having(
          (error) => error.failure,
          'failure',
          UserSoundStoreFailure.cancelled,
        ),
      ),
    );
    expect(await store.load(), isEmpty);
    expect(original.existsSync(), isTrue);
    expect(_audioCopies(directory), isEmpty);
  });

  test('来源文件打开失败不会留下音频副本', () async {
    await expectLater(
      store.import(
        const UserSoundSelection(
          fileName: 'missing.mp3',
          sourcePath: '/stillow-missing-user-sound.mp3',
        ),
      ),
      throwsA(
        isA<UserSoundStoreException>().having(
          (error) => error.failure,
          'failure',
          UserSoundStoreFailure.sourceUnavailable,
        ),
      ),
    );

    expect(_audioCopies(directory), isEmpty);
  });

  test('并发导入会立即拒绝第二个任务', () async {
    final original = await _writeSource(sourceDirectory, 'first.mp3', [1, 2]);
    final second = await _writeSource(sourceDirectory, 'second.mp3', [3, 4]);
    final started = Completer<void>();
    final hanging = _HangingAccess(started);
    store = LocalUserSoundStore(
      directoryProvider: () async => directory,
      access: hanging,
    );
    final first = store.import(_selection(original));
    await started.future;

    await expectLater(
      store.import(_selection(second)),
      throwsA(
        isA<UserSoundStoreException>().having(
          (error) => error.failure,
          'failure',
          UserSoundStoreFailure.importInProgress,
        ),
      ),
    );
    hanging.releaseHang();
    await first;
    expect(await store.load(), hasLength(1));
  });

  test('删除项目不会删除用户手机上的原文件', () async {
    final original = await _writeSource(sourceDirectory, 'lesson.mp3', [
      7,
      8,
      9,
    ]);
    final sound = await store.import(_selection(original));

    await store.delete(sound.id);

    expect(original.existsSync(), isTrue);
    expect(await original.readAsBytes(), [7, 8, 9]);
    expect(await store.load(), isEmpty);
  });

  test('原文件消失后启动时不再列出这条路径', () async {
    final original = await _writeSource(sourceDirectory, 'gone.mp3', [1, 2]);
    await store.import(_selection(original));
    await original.delete();

    expect(await store.load(), isEmpty);
  });

  test('旧版私有副本删除时仍会清掉 App 里的那份文件', () async {
    final soundsDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}user_sounds',
    );
    await soundsDirectory.create(recursive: true);
    final copy = File('${soundsDirectory.path}${Platform.pathSeparator}42.mp3');
    await copy.writeAsBytes([1, 2]);
    await File(
      '${soundsDirectory.path}${Platform.pathSeparator}user_sounds.json',
    ).writeAsString(
      '[{"id":"42","title":"old","sourceKind":"fileCopy",'
      '"relativePath":"42.mp3","originalFileName":"old.mp3",'
      '"loop":false,"attenuateLoops":false,'
      '"createdAt":"2026-01-01T00:00:00.000","defaultTimerMinutes":30}]',
    );

    await store.delete('42');

    expect(copy.existsSync(), isFalse);
    expect(await store.load(), isEmpty);
  });

  test('多次加入按添加顺序排成列表', () async {
    final first = await _writeSource(sourceDirectory, 'first.mp3', [1]);
    final second = await _writeSource(sourceDirectory, 'second.mp3', [2]);

    await store.import(_selection(first));
    await store.import(_selection(second));

    final restored = await store.load();
    expect(restored.map((sound) => sound.title), ['first', 'second']);
  });

  test('一次加入多条路径并保持选择顺序', () async {
    final first = await _writeSource(sourceDirectory, 'a.mp3', [1]);
    final second = await _writeSource(sourceDirectory, 'b.m4a', [2, 3]);

    final imported = await store.importAll([
      _selection(second),
      _selection(first),
    ]);

    expect(imported.map((sound) => sound.title), ['b', 'a']);
    expect(await File(imported.first.sourcePath!).readAsBytes(), [2, 3]);
    expect(_audioCopies(directory), isEmpty);
  });

  test('调整列表顺序后按新顺序恢复', () async {
    final first = await _writeSource(sourceDirectory, 'one.mp3', [1]);
    final second = await _writeSource(sourceDirectory, 'two.mp3', [2]);
    final imported = [
      await store.import(_selection(first)),
      await store.import(_selection(second)),
    ];

    await store.reorder([imported.last.id, imported.first.id]);

    expect((await store.load()).map((sound) => sound.id), [
      imported.last.id,
      imported.first.id,
    ]);
  });
}

Future<File> _writeSource(
  Directory directory,
  String name,
  List<int> bytes,
) async {
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

UserSoundSelection _selection(File file) => UserSoundSelection(
  fileName: file.uri.pathSegments.last,
  sourcePath: file.path,
  declaredSize: file.lengthSync(),
);

List<File> _audioCopies(Directory root) {
  final soundsDirectory = Directory(
    '${root.path}${Platform.pathSeparator}user_sounds',
  );
  if (!soundsDirectory.existsSync()) return const [];
  return soundsDirectory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.mp3') || file.path.endsWith('.m4a'))
      .toList();
}

final class _HangingAccess extends UserSoundAccess {
  _HangingAccess(this.started);

  final Completer<void> started;
  final Completer<void> _continue = Completer<void>();

  void releaseHang() {
    if (!_continue.isCompleted) _continue.complete();
  }

  @override
  Future<UserSoundAccessCheck> ensureReadable({
    required String sourcePath,
    String? accessBookmark,
    bool Function()? isCancelled,
  }) async {
    started.complete();
    await _continue.future;
    if (isCancelled?.call() ?? false) return UserSoundAccessCheck.missing;
    return const PluginUserSoundAccess().ensureReadable(
      sourcePath: sourcePath,
      accessBookmark: accessBookmark,
      isCancelled: isCancelled,
    );
  }

  @override
  Future<void> persist(String sourcePath) async {}

  @override
  Future<String?> refreshBookmark({
    required String sourcePath,
    required String accessBookmark,
  }) async => accessBookmark;

  @override
  Future<void> release(String sourcePath) async {}

  @override
  Future<UserSoundPlaybackHandle> beginPlayback({
    required String sourcePath,
    String? accessBookmark,
  }) async => UserSoundPlaybackHandle(filePath: sourcePath);

  @override
  Future<void> endPlayback() async {}
}

final class _RecordingAccess extends UserSoundAccess {
  _RecordingAccess({this.refreshedBookmark});

  final String? refreshedBookmark;
  final List<String> persisted = [];
  final List<String> released = [];

  @override
  Future<UserSoundAccessCheck> ensureReadable({
    required String sourcePath,
    String? accessBookmark,
    bool Function()? isCancelled,
  }) async => UserSoundAccessCheck.ok;

  @override
  Future<void> persist(String sourcePath) async {
    persisted.add(sourcePath);
  }

  @override
  Future<String?> refreshBookmark({
    required String sourcePath,
    required String accessBookmark,
  }) async => refreshedBookmark ?? accessBookmark;

  @override
  Future<void> release(String sourcePath) async {
    released.add(sourcePath);
  }

  @override
  Future<UserSoundPlaybackHandle> beginPlayback({
    required String sourcePath,
    String? accessBookmark,
  }) async => UserSoundPlaybackHandle(uri: Uri.parse(sourcePath));

  @override
  Future<void> endPlayback() async {}
}
