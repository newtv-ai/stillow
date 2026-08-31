import '../domain/sleep_history.dart';
import '../services/private_local_storage.dart';

abstract interface class SleepHistoryStore {
  Future<SleepHistorySnapshot> load();

  Future<void> saveAppSession(AppSleepSessionRecord record);

  Future<void> saveMorningCheckIn(MorningCheckIn checkIn);

  Future<void> replaceHealthSamples(
    List<HealthSleepSample> samples,
    DateTime syncedAt,
  );

  Future<void> deleteLocalDay(String dayKey);

  Future<void> clearHealthData();

  Future<void> clearAll();
}

class LocalSleepHistoryStore implements SleepHistoryStore {
  LocalSleepHistoryStore({
    DateTime Function()? clock,
    PrivateDirectoryProvider? directoryProvider,
  }) : _clock = clock ?? DateTime.now,
       _file = PrivateJsonFile(
         'sleep_history.json',
         directoryProvider: directoryProvider,
       );

  final DateTime Function() _clock;
  final PrivateJsonFile _file;
  Future<void> _pendingMutation = Future.value();

  @override
  Future<SleepHistorySnapshot> load() {
    late SleepHistorySnapshot result;
    final operation = _pendingMutation.then((_) async {
      result = await _readAndPersistPruned();
    });
    _pendingMutation = operation.catchError((_) {});
    return operation.then((_) => result);
  }

  @override
  Future<void> saveAppSession(AppSleepSessionRecord record) => _mutate((value) {
    final sessions = [
      record,
      ...value.appSessions.where((item) => item.id != record.id),
    ];
    return value.copyWith(appSessions: sessions);
  });

  @override
  Future<void> saveMorningCheckIn(MorningCheckIn checkIn) => _mutate((value) {
    final dayKey = sleepHistoryDayKey(checkIn.recordedAt);
    final checkIns = [
      checkIn,
      ...value.morningCheckIns.where(
        (item) => sleepHistoryDayKey(item.recordedAt) != dayKey,
      ),
    ];
    return value.copyWith(morningCheckIns: checkIns);
  });

  @override
  Future<void> replaceHealthSamples(
    List<HealthSleepSample> samples,
    DateTime syncedAt,
  ) => _mutate(
    (value) => value.copyWith(
      healthSamples: List.unmodifiable(samples),
      lastHealthSyncAt: syncedAt,
    ),
  );

  @override
  Future<void> deleteLocalDay(String dayKey) => _mutate(
    (value) => value.copyWith(
      appSessions: value.appSessions
          .where((item) => sleepSessionNightKey(item.startedAt) != dayKey)
          .toList(),
      morningCheckIns: value.morningCheckIns
          .where((item) => sleepHistoryDayKey(item.recordedAt) != dayKey)
          .toList(),
    ),
  );

  @override
  Future<void> clearHealthData() => _mutate(
    (value) =>
        value.copyWith(healthSamples: const [], clearLastHealthSyncAt: true),
  );

  @override
  Future<void> clearAll() => _mutate((_) => const SleepHistorySnapshot());

  Future<void> _mutate(
    SleepHistorySnapshot Function(SleepHistorySnapshot value) update,
  ) {
    final operation = _pendingMutation.then((_) async {
      final next = update(await _readAndPersistPruned()).pruned(_clock());
      await _file.write(next.toJson());
    });
    _pendingMutation = operation.catchError((_) {});
    return operation;
  }

  Future<SleepHistorySnapshot> _readAndPersistPruned() async {
    final raw = SleepHistorySnapshot.fromJson(await _file.read());
    final pruned = raw.pruned(_clock());
    if (_retentionChanged(raw, pruned)) {
      await _file.write(pruned.toJson());
    }
    return pruned;
  }

  static bool _retentionChanged(
    SleepHistorySnapshot raw,
    SleepHistorySnapshot pruned,
  ) =>
      raw.appSessions.length != pruned.appSessions.length ||
      raw.morningCheckIns.length != pruned.morningCheckIns.length ||
      raw.healthSamples.length != pruned.healthSamples.length;
}
