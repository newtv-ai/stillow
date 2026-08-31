import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/data/sleep_history_store.dart';
import 'package:stillow/domain/sleep_history.dart';
import 'package:stillow/domain/stillow_models.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 8, 11, 9);

  test('本地睡眠记录只保留最近 30 天并可按夜晚删除', () async {
    final store = MemorySleepHistoryStore(
      const SleepHistorySnapshot(),
      () => now,
    );
    await store.saveAppSession(_session('old', DateTime(2026, 7, 1, 23)));
    await store.saveAppSession(_session('recent', DateTime(2026, 8, 10, 23)));

    expect((await store.load()).appSessions.map((item) => item.id), ['recent']);

    await store.deleteLocalDay('2026-08-11');
    expect((await store.load()).appSessions, isEmpty);
  });

  test('同一天的晨间感受会被最新选择温和替换', () async {
    final store = MemorySleepHistoryStore(
      const SleepHistorySnapshot(),
      () => now,
    );
    await store.saveMorningCheckIn(
      MorningCheckIn(
        id: 'first',
        recordedAt: DateTime(2026, 8, 11, 7),
        feeling: MorningFeeling.tired,
      ),
    );
    await store.saveMorningCheckIn(
      MorningCheckIn(
        id: 'second',
        recordedAt: DateTime(2026, 8, 11, 8),
        feeling: MorningFeeling.rested,
      ),
    );

    final checkIns = (await store.load()).morningCheckIns;
    expect(checkIns, hasLength(1));
    expect(checkIns.single.id, 'second');
    expect(checkIns.single.feeling, MorningFeeling.rested);
  });

  test('健康数据只保存归一化睡眠记录并可单独清除', () async {
    final store = MemorySleepHistoryStore(
      const SleepHistorySnapshot(),
      () => now,
    );
    final samples = [
      HealthSleepSample(
        id: 'sleep-1',
        startedAt: DateTime(2026, 8, 10, 23),
        endedAt: DateTime(2026, 8, 11, 7),
        stage: HealthSleepStage.session,
      ),
    ];

    await store.replaceHealthSamples(samples, now);
    expect((await store.load()).healthSamples, hasLength(1));

    await store.clearHealthData();
    final cleared = await store.load();
    expect(cleared.healthSamples, isEmpty);
    expect(cleared.lastHealthSyncAt, isNull);
  });

  test('跨午夜的阶段记录汇总为同一个夜晚且不重复累加阶段时长', () {
    final samples = [
      HealthSleepSample(
        id: 'session',
        startedAt: DateTime(2026, 8, 10, 23),
        endedAt: DateTime(2026, 8, 11, 7),
        stage: HealthSleepStage.session,
      ),
      HealthSleepSample(
        id: 'deep',
        startedAt: DateTime(2026, 8, 11, 1),
        endedAt: DateTime(2026, 8, 11, 2),
        stage: HealthSleepStage.deep,
      ),
    ];

    final summaries = summarizeSleepNights(samples);

    expect(summaries, hasLength(1));
    expect(summaries.single.recordedWindow, const Duration(hours: 8));
    expect(summaries.single.stages, contains(HealthSleepStage.deep));
  });

  test('同一天的小睡不会与夜间主睡眠拼成虚假长区间', () {
    final samples = [
      HealthSleepSample(
        id: 'night',
        startedAt: DateTime(2026, 8, 10, 23),
        endedAt: DateTime(2026, 8, 11, 7),
        stage: HealthSleepStage.session,
      ),
      HealthSleepSample(
        id: 'nap',
        startedAt: DateTime(2026, 8, 11, 14),
        endedAt: DateTime(2026, 8, 11, 15),
        stage: HealthSleepStage.session,
      ),
    ];

    final summaries = summarizeSleepNights(samples);

    expect(summaries, hasLength(1));
    expect(summaries.single.startedAt, DateTime(2026, 8, 10, 23));
    expect(summaries.single.recordedWindow, const Duration(hours: 8));
  });

  test('损坏的本地历史不会阻止应用启动', () async {
    final directory = await Directory.systemTemp.createTemp('stillow-history-');
    addTearDown(() async {
      if (directory.existsSync()) await directory.delete(recursive: true);
    });
    await File(
      '${directory.path}${Platform.pathSeparator}sleep_history.json',
    ).writeAsString('{broken');

    final snapshot = await LocalSleepHistoryStore(
      clock: () => now,
      directoryProvider: () async => directory,
    ).load();

    expect(snapshot.isEmpty, isTrue);
  });

  test('历史 JSON 中错误的时间戳或列表类型不会阻止读取', () {
    final snapshot = SleepHistorySnapshot.fromJson({
      'lastHealthSyncAt': 123,
      'appSessions': 'broken',
    });
    expect(snapshot.isEmpty, isTrue);
    expect(snapshot.lastHealthSyncAt, isNull);
  });

  test('读取历史时会把超过 30 天的记录从磁盘删除', () async {
    final directory = await Directory.systemTemp.createTemp(
      'stillow-history-prune-',
    );
    addTearDown(() async {
      if (directory.existsSync()) await directory.delete(recursive: true);
    });
    final file = File(
      '${directory.path}${Platform.pathSeparator}sleep_history.json',
    );
    final stale = SleepHistorySnapshot(
      appSessions: [
        _session('old', DateTime(2026, 7, 1, 23)),
        _session('recent', DateTime(2026, 8, 29, 23)),
      ],
    );
    await file.writeAsString(jsonEncode(stale.toJson()));

    final loaded = await LocalSleepHistoryStore(
      clock: () => DateTime(2026, 8, 30, 9),
      directoryProvider: () async => directory,
    ).load();

    expect(loaded.appSessions.map((item) => item.id), ['recent']);
    final disk = jsonDecode(await file.readAsString()) as Map;
    expect((disk['appSessions'] as List).map((item) => (item as Map)['id']), [
      'recent',
    ]);
  });
}

AppSleepSessionRecord _session(String id, DateTime startedAt) =>
    AppSleepSessionRecord(
      id: id,
      startedAt: startedAt,
      sessionId: 'rain',
      sessionTitle: '轻雨',
      context: SleepUseContext.bedtime,
      listenedSeconds: 1200,
    );
