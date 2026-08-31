import 'package:stillow/data/preference_store.dart';
import 'package:stillow/data/sleep_history_store.dart';
import 'package:stillow/domain/sleep_history.dart';
import 'package:stillow/domain/stillow_models.dart';
import 'package:stillow/services/remote_audio_controller.dart';
import 'package:stillow/services/sleep_health_gateway.dart';

class MemoryPreferenceStore implements PreferenceStore {
  MemoryPreferenceStore([this.profile = const UserProfile()]);

  UserProfile profile;

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile profile) async {
    this.profile = profile;
  }
}

class MemorySleepHistoryStore implements SleepHistoryStore {
  MemorySleepHistoryStore([
    this.snapshot = const SleepHistorySnapshot(),
    DateTime Function()? clock,
  ]) : _clock = clock ?? DateTime.now;

  SleepHistorySnapshot snapshot;
  final DateTime Function() _clock;

  @override
  Future<SleepHistorySnapshot> load() async {
    snapshot = snapshot.pruned(_clock());
    return snapshot;
  }

  @override
  Future<void> saveAppSession(AppSleepSessionRecord record) async {
    snapshot = snapshot
        .copyWith(
          appSessions: [
            record,
            ...snapshot.appSessions.where((item) => item.id != record.id),
          ],
        )
        .pruned(_clock());
  }

  @override
  Future<void> saveMorningCheckIn(MorningCheckIn checkIn) async {
    final dayKey = sleepHistoryDayKey(checkIn.recordedAt);
    snapshot = snapshot
        .copyWith(
          morningCheckIns: [
            checkIn,
            ...snapshot.morningCheckIns.where(
              (item) => sleepHistoryDayKey(item.recordedAt) != dayKey,
            ),
          ],
        )
        .pruned(_clock());
  }

  @override
  Future<void> replaceHealthSamples(
    List<HealthSleepSample> samples,
    DateTime syncedAt,
  ) async {
    snapshot = snapshot
        .copyWith(healthSamples: samples, lastHealthSyncAt: syncedAt)
        .pruned(_clock());
  }

  @override
  Future<void> deleteLocalDay(String dayKey) async {
    snapshot = snapshot.copyWith(
      appSessions: snapshot.appSessions
          .where((item) => sleepSessionNightKey(item.startedAt) != dayKey)
          .toList(),
      morningCheckIns: snapshot.morningCheckIns
          .where((item) => sleepHistoryDayKey(item.recordedAt) != dayKey)
          .toList(),
    );
  }

  @override
  Future<void> clearHealthData() async {
    snapshot = snapshot.copyWith(
      healthSamples: const [],
      clearLastHealthSyncAt: true,
    );
  }

  @override
  Future<void> clearAll() async {
    snapshot = const SleepHistorySnapshot();
  }
}

class MemorySleepHealthGateway implements SleepHealthGateway {
  MemorySleepHealthGateway({
    this.availability = SleepHealthAvailability.available,
    this.result = const SleepHealthSyncResult(
      state: SleepHealthSyncState.noData,
    ),
    this.hostPlatform = HealthHostPlatform.android,
  });

  SleepHealthAvailability availability;
  SleepHealthSyncResult result;
  bool installOpened = false;
  bool disconnected = false;

  @override
  final HealthHostPlatform hostPlatform;

  @override
  Future<SleepHealthAvailability> checkAvailability() async => availability;

  @override
  Future<SleepHealthSyncResult> requestAndRead() async => result;

  @override
  Future<void> openInstallOrUpdate() async => installOpened = true;

  @override
  Future<void> disconnect() async => disconnected = true;
}

class FakeSleepPlaybackController extends SleepPlaybackController {
  @override
  PlaybackStatus status = PlaybackStatus.idle;

  @override
  PlaybackFailure? failure;

  @override
  DateTime? sleepTimerEndsAt;

  PlaybackItem? item;

  @override
  bool get isPlaying => status == PlaybackStatus.playing;

  @override
  Future<void> start(PlaybackItem nextItem) async {
    item = nextItem;
    failure = null;
    status = PlaybackStatus.loading;
    notifyListeners();
    status = PlaybackStatus.playing;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    status = PlaybackStatus.paused;
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    status = PlaybackStatus.playing;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    status = PlaybackStatus.idle;
    sleepTimerEndsAt = null;
    notifyListeners();
  }

  @override
  void setSleepTimer(Duration? duration) {
    sleepTimerEndsAt = duration == null ? null : DateTime.now().add(duration);
    notifyListeners();
  }

  void emitComplete() {
    status = PlaybackStatus.complete;
    notifyListeners();
  }

  void emitError(PlaybackFailure nextFailure) {
    failure = nextFailure;
    status = PlaybackStatus.error;
    notifyListeners();
  }
}
