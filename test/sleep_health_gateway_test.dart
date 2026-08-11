import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:stillow/domain/sleep_history.dart';
import 'package:stillow/services/sleep_health_gateway.dart';

void main() {
  test('健康平台数据只归一化睡眠时段和阶段', () {
    final start = DateTime(2026, 8, 10, 23);
    final end = DateTime(2026, 8, 11, 7);
    final points = [
      _point(
        uuid: 'sleep',
        type: HealthDataType.SLEEP_SESSION,
        start: start,
        end: end,
        sourceName: 'Test Watch',
      ),
      _point(
        uuid: 'heart',
        type: HealthDataType.HEART_RATE,
        start: start,
        end: start.add(const Duration(minutes: 1)),
        sourceName: 'Test Watch',
      ),
    ];

    final samples = normalizeHealthSleepPoints(points);

    expect(samples, hasLength(1));
    expect(samples.single.id, startsWith('SLEEP_SESSION:'));
    expect(samples.single.stage, HealthSleepStage.session);
    expect(samples.single.duration, const Duration(hours: 8));
  });

  test('原始 UUID 与来源不同的同一阶段记录会被去重', () {
    final first = _point(
      uuid: 'sleep',
      type: HealthDataType.SLEEP_DEEP,
      start: DateTime(2026, 8, 11, 1),
      end: DateTime(2026, 8, 11, 2),
      sourceName: 'Watch A',
    );
    final duplicate = _point(
      uuid: 'another-raw-uuid',
      type: HealthDataType.SLEEP_DEEP,
      start: DateTime(2026, 8, 11, 1),
      end: DateTime(2026, 8, 11, 2),
      sourceName: 'Watch B',
    );

    final samples = normalizeHealthSleepPoints([first, duplicate]);

    expect(samples, hasLength(1));
  });
}

HealthDataPoint _point({
  required String uuid,
  required HealthDataType type,
  required DateTime start,
  required DateTime end,
  required String sourceName,
}) => HealthDataPoint(
  uuid: uuid,
  value: NumericHealthValue(numericValue: 1),
  type: type,
  unit: HealthDataUnit.MINUTE,
  dateFrom: start,
  dateTo: end,
  sourcePlatform: HealthPlatformType.googleHealthConnect,
  sourceDeviceId: 'device-id-is-not-copied',
  sourceId: 'source-id-is-not-copied',
  sourceName: sourceName,
);
