import 'dart:io';

import 'package:flutter/services.dart';
import 'package:health/health.dart';

import '../domain/sleep_history.dart';

enum SleepHealthAvailability { available, installRequired, unavailable }

enum SleepHealthSyncState {
  synced,
  noData,
  permissionDeclined,
  unavailable,
  failed,
}

enum HealthHostPlatform { android, ios, unsupported }

class SleepHealthSyncResult {
  const SleepHealthSyncResult({
    required this.state,
    this.samples = const [],
    this.message,
  });

  final SleepHealthSyncState state;
  final List<HealthSleepSample> samples;
  final String? message;
}

abstract interface class SleepHealthGateway {
  HealthHostPlatform get hostPlatform;

  Future<SleepHealthAvailability> checkAvailability();

  Future<SleepHealthSyncResult> requestAndRead();

  Future<void> openInstallOrUpdate();

  Future<void> disconnect();
}

class PluginSleepHealthGateway implements SleepHealthGateway {
  PluginSleepHealthGateway({
    Health? health,
    HealthHostPlatform? hostPlatform,
    DateTime Function()? clock,
  }) : _health = health ?? Health(),
       hostPlatform = hostPlatform ?? _currentPlatform(),
       _clock = clock ?? DateTime.now;

  final Health _health;
  final DateTime Function() _clock;

  @override
  final HealthHostPlatform hostPlatform;

  @override
  Future<SleepHealthAvailability> checkAvailability() async {
    if (hostPlatform == HealthHostPlatform.unsupported) {
      return SleepHealthAvailability.unavailable;
    }
    if (hostPlatform == HealthHostPlatform.ios) {
      return SleepHealthAvailability.available;
    }
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return switch (status) {
        HealthConnectSdkStatus.sdkAvailable =>
          SleepHealthAvailability.available,
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
          SleepHealthAvailability.installRequired,
        _ => SleepHealthAvailability.unavailable,
      };
    } on PlatformException {
      return SleepHealthAvailability.unavailable;
    }
  }

  @override
  Future<SleepHealthSyncResult> requestAndRead() async {
    final availability = await checkAvailability();
    if (availability != SleepHealthAvailability.available) {
      return const SleepHealthSyncResult(
        state: SleepHealthSyncState.unavailable,
        message: '这台设备暂时不能读取系统睡眠记录。',
      );
    }

    final types = _sleepTypesFor(hostPlatform);
    final permissions = List<HealthDataAccess>.filled(
      types.length,
      HealthDataAccess.READ,
    );
    try {
      await _health.configure();
      final authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      if (!authorized) {
        return const SleepHealthSyncResult(
          state: SleepHealthSyncState.permissionDeclined,
          message: '没有取得读取权限。以后想连接时，再从这里开始就好。',
        );
      }

      final now = _clock();
      final points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: now.subtract(const Duration(days: 30)),
        endTime: now,
      );
      final samples = normalizeHealthSleepPoints(points);
      if (samples.isEmpty) {
        return const SleepHealthSyncResult(
          state: SleepHealthSyncState.noData,
          message: '近 30 天没有读到睡眠记录，也可能是系统没有开放读取。',
        );
      }
      return SleepHealthSyncResult(
        state: SleepHealthSyncState.synced,
        samples: samples,
        message: '已更新这台设备中的最近记录。',
      );
    } on UnsupportedError {
      return const SleepHealthSyncResult(
        state: SleepHealthSyncState.unavailable,
        message: '这台设备暂时不能读取系统睡眠记录。',
      );
    } on PlatformException {
      return const SleepHealthSyncResult(
        state: SleepHealthSyncState.failed,
        message: '这次没有同步好。设备解锁后再试也可以。',
      );
    } catch (_) {
      return const SleepHealthSyncResult(
        state: SleepHealthSyncState.failed,
        message: '这次没有同步好，稍后再试也可以。',
      );
    }
  }

  @override
  Future<void> openInstallOrUpdate() async {
    if (hostPlatform != HealthHostPlatform.android) return;
    await _health.installHealthConnect();
  }

  @override
  Future<void> disconnect() async {
    if (hostPlatform != HealthHostPlatform.android) return;
    await _health.configure();
    await _health.revokePermissions();
  }

  static HealthHostPlatform _currentPlatform() {
    if (Platform.isAndroid) return HealthHostPlatform.android;
    if (Platform.isIOS) return HealthHostPlatform.ios;
    return HealthHostPlatform.unsupported;
  }
}

List<HealthSleepSample> normalizeHealthSleepPoints(
  Iterable<HealthDataPoint> points,
) {
  final samples = <String, HealthSleepSample>{};
  for (final point in points) {
    final stage = _stageFor(point.type);
    if (stage == null || !point.dateTo.isAfter(point.dateFrom)) continue;
    final id =
        '${point.type.name}:'
        '${point.dateFrom.microsecondsSinceEpoch}:'
        '${point.dateTo.microsecondsSinceEpoch}';
    samples[id] = HealthSleepSample(
      id: id,
      startedAt: point.dateFrom,
      endedAt: point.dateTo,
      stage: stage,
    );
  }
  final result = samples.values.toList()
    ..sort((a, b) => b.endedAt.compareTo(a.endedAt));
  return List.unmodifiable(result);
}

List<HealthDataType> _sleepTypesFor(HealthHostPlatform platform) =>
    switch (platform) {
      HealthHostPlatform.ios => const [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
      ],
      HealthHostPlatform.android => const [
        HealthDataType.SLEEP_SESSION,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_AWAKE_IN_BED,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_OUT_OF_BED,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_UNKNOWN,
      ],
      HealthHostPlatform.unsupported => const [],
    };

HealthSleepStage? _stageFor(HealthDataType type) => switch (type) {
  HealthDataType.SLEEP_SESSION => HealthSleepStage.session,
  HealthDataType.SLEEP_IN_BED => HealthSleepStage.inBed,
  HealthDataType.SLEEP_ASLEEP => HealthSleepStage.asleep,
  HealthDataType.SLEEP_AWAKE => HealthSleepStage.awake,
  HealthDataType.SLEEP_AWAKE_IN_BED => HealthSleepStage.awakeInBed,
  HealthDataType.SLEEP_DEEP => HealthSleepStage.deep,
  HealthDataType.SLEEP_LIGHT => HealthSleepStage.light,
  HealthDataType.SLEEP_REM => HealthSleepStage.rem,
  HealthDataType.SLEEP_OUT_OF_BED => HealthSleepStage.outOfBed,
  HealthDataType.SLEEP_UNKNOWN => HealthSleepStage.unknown,
  _ => null,
};
