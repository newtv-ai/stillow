import 'stillow_models.dart';

enum MorningFeeling { rested, ordinary, tired }

enum HealthSleepStage {
  session,
  inBed,
  asleep,
  awake,
  awakeInBed,
  deep,
  light,
  rem,
  outOfBed,
  unknown,
}

class AppSleepSessionRecord {
  const AppSleepSessionRecord({
    required this.id,
    required this.startedAt,
    required this.sessionId,
    required this.sessionTitle,
    required this.context,
    required this.listenedSeconds,
  });

  final String id;
  final DateTime startedAt;
  final String sessionId;
  final String sessionTitle;
  final SleepUseContext context;
  final int listenedSeconds;

  Map<String, Object> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'sessionId': sessionId,
    'sessionTitle': sessionTitle,
    'context': context.name,
    'listenedSeconds': listenedSeconds,
  };

  static AppSleepSessionRecord? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final id = json['id'];
    final startedAt = DateTime.tryParse(json['startedAt'] as String? ?? '');
    final sessionId = json['sessionId'];
    final sessionTitle = json['sessionTitle'];
    final context = _enumByName(
      SleepUseContext.values,
      json['context'] as String?,
    );
    final listenedSeconds = json['listenedSeconds'];
    if (id is! String ||
        startedAt == null ||
        sessionId is! String ||
        sessionTitle is! String ||
        context == null ||
        listenedSeconds is! num) {
      return null;
    }
    return AppSleepSessionRecord(
      id: id,
      startedAt: startedAt,
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      context: context,
      listenedSeconds: listenedSeconds.toInt().clamp(0, 86400),
    );
  }
}

class MorningCheckIn {
  const MorningCheckIn({
    required this.id,
    required this.recordedAt,
    required this.feeling,
  });

  final String id;
  final DateTime recordedAt;
  final MorningFeeling feeling;

  Map<String, Object> toJson() => {
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'feeling': feeling.name,
  };

  static MorningCheckIn? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final id = json['id'];
    final recordedAt = DateTime.tryParse(json['recordedAt'] as String? ?? '');
    final feeling = _enumByName(
      MorningFeeling.values,
      json['feeling'] as String?,
    );
    if (id is! String || recordedAt == null || feeling == null) return null;
    return MorningCheckIn(id: id, recordedAt: recordedAt, feeling: feeling);
  }
}

class HealthSleepSample {
  const HealthSleepSample({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.stage,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final HealthSleepStage stage;

  Duration get duration => endedAt.difference(startedAt);

  Map<String, Object> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'stage': stage.name,
  };

  static HealthSleepSample? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final id = json['id'];
    final startedAt = DateTime.tryParse(json['startedAt'] as String? ?? '');
    final endedAt = DateTime.tryParse(json['endedAt'] as String? ?? '');
    final stage = _enumByName(
      HealthSleepStage.values,
      json['stage'] as String?,
    );
    if (id is! String ||
        startedAt == null ||
        endedAt == null ||
        !endedAt.isAfter(startedAt) ||
        stage == null) {
      return null;
    }
    return HealthSleepSample(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      stage: stage,
    );
  }
}

class SleepHistorySnapshot {
  const SleepHistorySnapshot({
    this.appSessions = const [],
    this.morningCheckIns = const [],
    this.healthSamples = const [],
    this.lastHealthSyncAt,
  });

  final List<AppSleepSessionRecord> appSessions;
  final List<MorningCheckIn> morningCheckIns;
  final List<HealthSleepSample> healthSamples;
  final DateTime? lastHealthSyncAt;

  bool get isEmpty =>
      appSessions.isEmpty && morningCheckIns.isEmpty && healthSamples.isEmpty;

  SleepHistorySnapshot copyWith({
    List<AppSleepSessionRecord>? appSessions,
    List<MorningCheckIn>? morningCheckIns,
    List<HealthSleepSample>? healthSamples,
    DateTime? lastHealthSyncAt,
    bool clearLastHealthSyncAt = false,
  }) => SleepHistorySnapshot(
    appSessions: appSessions ?? this.appSessions,
    morningCheckIns: morningCheckIns ?? this.morningCheckIns,
    healthSamples: healthSamples ?? this.healthSamples,
    lastHealthSyncAt: clearLastHealthSyncAt
        ? null
        : lastHealthSyncAt ?? this.lastHealthSyncAt,
  );

  SleepHistorySnapshot pruned(DateTime now) {
    final cutoff = now.subtract(const Duration(days: 30));
    final sessions =
        appSessions
            .where((record) => !record.startedAt.isBefore(cutoff))
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final checkIns =
        morningCheckIns
            .where((record) => !record.recordedAt.isBefore(cutoff))
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final samples =
        healthSamples
            .where((record) => !record.endedAt.isBefore(cutoff))
            .toList()
          ..sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return SleepHistorySnapshot(
      appSessions: List.unmodifiable(sessions),
      morningCheckIns: List.unmodifiable(checkIns),
      healthSamples: List.unmodifiable(samples),
      lastHealthSyncAt: lastHealthSyncAt,
    );
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'appSessions': appSessions.map((item) => item.toJson()).toList(),
    'morningCheckIns': morningCheckIns.map((item) => item.toJson()).toList(),
    'healthSamples': healthSamples.map((item) => item.toJson()).toList(),
    'lastHealthSyncAt': lastHealthSyncAt?.toIso8601String(),
  };

  static SleepHistorySnapshot fromJson(Object? value) {
    if (value is! Map) return const SleepHistorySnapshot();
    final json = Map<String, dynamic>.from(value);
    return SleepHistorySnapshot(
      appSessions: _decodeList(
        json['appSessions'],
        AppSleepSessionRecord.tryFromJson,
      ),
      morningCheckIns: _decodeList(
        json['morningCheckIns'],
        MorningCheckIn.tryFromJson,
      ),
      healthSamples: _decodeList(
        json['healthSamples'],
        HealthSleepSample.tryFromJson,
      ),
      lastHealthSyncAt: json['lastHealthSyncAt'] is String
          ? DateTime.tryParse(json['lastHealthSyncAt'] as String)
          : null,
    );
  }
}

class NightSleepSummary {
  const NightSleepSummary({
    required this.day,
    required this.startedAt,
    required this.endedAt,
    required this.stages,
    required this.segments,
  });

  final DateTime day;
  final DateTime startedAt;
  final DateTime endedAt;
  final Set<HealthSleepStage> stages;
  final List<HealthSleepSample> segments;

  Duration get recordedWindow => endedAt.difference(startedAt);
}

List<NightSleepSummary> summarizeSleepNights(
  Iterable<HealthSleepSample> samples,
) {
  final ordered = samples.toList()
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  if (ordered.isEmpty) return const [];

  const maximumGap = Duration(hours: 2);
  final clusters = <List<HealthSleepSample>>[];
  for (final sample in ordered) {
    if (clusters.isEmpty) {
      clusters.add([sample]);
      continue;
    }
    final current = clusters.last;
    final currentEnd = current
        .map((item) => item.endedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    if (!sample.startedAt.isAfter(currentEnd.add(maximumGap))) {
      current.add(sample);
    } else {
      clusters.add([sample]);
    }
  }

  final candidates = clusters.map(_summaryFromCluster).toList();
  final primaryByDay = <String, NightSleepSummary>{};
  for (final summary in candidates) {
    final key = _dayKey(summary.endedAt.toLocal());
    final current = primaryByDay[key];
    if (current == null ||
        summary.recordedWindow > current.recordedWindow ||
        (summary.recordedWindow == current.recordedWindow &&
            summary.endedAt.isAfter(current.endedAt))) {
      primaryByDay[key] = summary;
    }
  }
  final summaries = primaryByDay.values.toList()
    ..sort((a, b) => b.endedAt.compareTo(a.endedAt));
  return List.unmodifiable(summaries);
}

NightSleepSummary _summaryFromCluster(List<HealthSleepSample> group) {
  var startedAt = group.first.startedAt;
  var endedAt = group.first.endedAt;
  final stages = <HealthSleepStage>{};
  for (final sample in group) {
    if (sample.startedAt.isBefore(startedAt)) startedAt = sample.startedAt;
    if (sample.endedAt.isAfter(endedAt)) endedAt = sample.endedAt;
    stages.add(sample.stage);
  }
  final localDay = endedAt.toLocal();
  return NightSleepSummary(
    day: DateTime(localDay.year, localDay.month, localDay.day),
    startedAt: startedAt,
    endedAt: endedAt,
    stages: Set.unmodifiable(stages),
    segments: List.unmodifiable(group),
  );
}

String sleepHistoryDayKey(DateTime value) => _dayKey(value.toLocal());

String sleepSessionNightKey(DateTime value) {
  final local = value.toLocal();
  final nightDay = local.hour >= 12
      ? DateTime(local.year, local.month, local.day + 1)
      : DateTime(local.year, local.month, local.day);
  return _dayKey(nightDay);
}

String _dayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

List<T> _decodeList<T>(Object? value, T? Function(Object?) decode) {
  if (value is! List) return const [];
  return List.unmodifiable(value.map(decode).whereType<T>());
}
