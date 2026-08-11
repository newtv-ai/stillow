import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/stillow_models.dart';

class ContentCatalog {
  ContentCatalog({
    required this.schemaVersion,
    required List<GuidedSession> items,
  }) : items = List.unmodifiable(items);

  final int schemaVersion;
  final List<GuidedSession> items;

  static Future<ContentCatalog> loadAsset({
    String path = 'assets/content/audio_catalog.json',
  }) async {
    final jsonText = await rootBundle.loadString(path);
    return ContentCatalog.fromJsonString(jsonText);
  }

  factory ContentCatalog.fromJsonString(String jsonText) {
    final root = jsonDecode(jsonText) as Map<String, dynamic>;
    final rawItems = root['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map((item) => _sessionFromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    if (items.isEmpty) {
      throw const FormatException('音频素材目录不能为空');
    }

    return ContentCatalog(
      schemaVersion: root['schemaVersion'] as int? ?? 1,
      items: items,
    );
  }

  List<GuidedSession> sessionsFor(ContentRegion region) {
    final result =
        items
            .where(
              (item) =>
                  item.isPlaybackEligible && item.regions.contains(region),
            )
            .toList(growable: false)
          ..sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

  List<GuidedSession> coursesFor(ContentRegion region) => sessionsFor(
    region,
  ).where((session) => session.kind == SessionKind.lecture).toList();

  List<GuidedSession> ambientFor(ContentRegion region) => sessionsFor(
    region,
  ).where((session) => session.kind != SessionKind.lecture).toList();

  GuidedSession? offlineFallbackFor(
    GuidedSession session,
    ContentRegion region,
  ) {
    if (session.playbackType == PlaybackType.assetAudio) return null;
    final available = sessionsFor(region).where(
      (candidate) =>
          candidate.playbackType == PlaybackType.assetAudio &&
          candidate.id != session.id,
    );
    final sameKind = available.where(
      (candidate) => candidate.kind == session.kind,
    );
    return sameKind.isNotEmpty
        ? sameKind.first
        : (available.isNotEmpty ? available.first : null);
  }

  GuidedSession? findById(String? id) {
    if (id == null) return null;
    for (final session in items) {
      if (session.id == id) return session;
    }
    return null;
  }

  GuidedSession recommend(
    UserProfile profile,
    ContentRegion region, [
    NightState? state,
  ]) {
    if (state == NightState.nightAwake) {
      return recommendNightRescue(profile, region);
    }
    final available = sessionsFor(region);
    if (available.isEmpty) {
      throw StateError('当前地区没有可用素材');
    }

    final goal = _goalTag(profile, state);
    final ranked =
        available
            .map(
              (session) => (
                session: session,
                score: _score(
                  session,
                  profile,
                  goal,
                  SleepUseContext.bedtime,
                  region,
                ),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));
    return ranked.first.session;
  }

  GuidedSession recommendNightRescue(
    UserProfile profile,
    ContentRegion region,
  ) {
    final nightSessions = ambientFor(region)
        .where((session) => session.tags.contains('night_awake'))
        .toList(growable: false);
    if (nightSessions.isEmpty) return recommend(profile, region);
    final ranked =
        nightSessions
            .map(
              (session) => (
                session: session,
                score: _score(
                  session,
                  profile,
                  'night_awake',
                  SleepUseContext.nightAwake,
                  region,
                ),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));
    return ranked.first.session;
  }

  static GuidedSession _sessionFromJson(Map<String, dynamic> json) {
    final kind = SessionKind.values.byName(_requiredString(json, 'kind'));
    return GuidedSession(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      subtitle: _requiredString(json, 'subtitle'),
      shortLabel: _requiredString(json, 'shortLabel'),
      kind: kind,
      tags: ((json['tags'] as List<dynamic>? ?? const []))
          .cast<String>()
          .toSet(),
      regions: ((json['regions'] as List<dynamic>? ?? const []))
          .cast<String>()
          .map(
            (region) => switch (region) {
              'CN' => ContentRegion.mainlandChina,
              'INTL' => ContentRegion.international,
              _ => throw FormatException('未知地区代码: $region'),
            },
          )
          .toSet(),
      provider: _requiredString(json, 'provider'),
      playbackType: PlaybackType.values.byName(
        _requiredString(json, 'playbackType'),
      ),
      playbackUrl: Uri.parse(_requiredString(json, 'playbackUrl')),
      adFree: json['adFree'] as bool? ?? false,
      rightsStatus: json['rightsStatus'] as String? ?? 'unknown',
      sourcePage: Uri.parse(_requiredString(json, 'sourcePage')),
      sourceTitle: _requiredString(json, 'sourceTitle'),
      creator: _requiredString(json, 'creator'),
      licenseName: _requiredString(json, 'licenseName'),
      licenseUrl: Uri.parse(_requiredString(json, 'licenseUrl')),
      loop: json['loop'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      languageCode:
          json['languageCode'] as String? ??
          (kind == SessionKind.lecture ? 'en' : 'zxx'),
      assetPath: json['assetPath'] as String?,
      sha256: json['sha256'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('素材字段 $key 不能为空');
    }
    return value;
  }

  static String _goalTag(UserProfile profile, NightState? state) {
    return switch (state) {
      NightState.tenseBody => 'relax_body',
      NightState.noisyRoom => 'mask_noise',
      NightState.busyMind => 'quiet_mind',
      NightState.notSleepy => 'not_sleepy',
      NightState.sleepPressure => 'sleep_pressure',
      NightState.nightAwake => 'night_awake',
      NightState.unsure || null => switch (profile.supportNeed) {
        SupportNeed.relaxBody => 'relax_body',
        SupportNeed.maskNoise => 'mask_noise',
        SupportNeed.gentleCompany => 'gentle_company',
        SupportNeed.notSleepy => 'not_sleepy',
        SupportNeed.sleepPressure => 'sleep_pressure',
        SupportNeed.nightAwake => 'night_awake',
        SupportNeed.quietMind || null => 'quiet_mind',
      },
    };
  }

  static int _score(
    GuidedSession session,
    UserProfile profile,
    String goal,
    SleepUseContext context,
    ContentRegion region,
  ) {
    var score = session.priority;
    if (session.tags.contains(goal)) score += 100;
    if (goal == 'not_sleepy') {
      if (session.kind == SessionKind.lecture) {
        score += 90;
        final duration = session.durationSeconds ?? 0;
        score += duration >= 1800 ? 45 : -30;
        if (region == ContentRegion.mainlandChina &&
            session.languageCode == 'zh') {
          score += 60;
        }
      }
      if (session.kind == SessionKind.narrative) score += 55;
      if (session.kind == SessionKind.guidedVoice) score -= 25;
    }
    if (goal == 'sleep_pressure') {
      if (session.tags.contains('minimal')) score += 70;
      if (session.tags.contains('guided')) score += 25;
      if (session.kind == SessionKind.lecture) score -= 35;
    }
    if (goal == 'night_awake' && !session.tags.contains('night_awake')) {
      score -= 120;
    }

    score += switch (profile.soundPreference) {
      SoundPreference.softVoice => session.tags.contains('soft_voice') ? 28 : 0,
      SoundPreference.nature => session.tags.contains('nature') ? 28 : 0,
      SoundPreference.minimal => session.tags.contains('minimal') ? 28 : 0,
      SoundPreference.familiarMusic => session.tags.contains('music') ? 28 : 0,
      null => 0,
    };

    score += switch (profile.guidancePreference) {
      GuidancePreference.stepByStep => session.tags.contains('guided') ? 22 : 0,
      GuidancePreference.occasional => session.tags.contains('guided') ? 8 : 0,
      GuidancePreference.ambientOnly =>
        session.tags.contains('ambient') ? 24 : -24,
      null => 0,
    };

    if (profile.lastFeedback == SessionFeedback.notForMe &&
        profile.lastSessionId == session.id) {
      score -= 80;
    }
    score += (profile.sessionAffinities[session.id] ?? 0) * 5;
    score += (profile.tagAffinities['kind:${session.kind.name}'] ?? 0) * 3;
    score +=
        (profile.tagAffinities['context:${context.name}:kind:${session.kind.name}'] ??
            0) *
        5;
    for (final tag in session.tags) {
      score += (profile.tagAffinities[tag] ?? 0) * 3;
    }
    return score;
  }
}

abstract final class ContentRegionResolver {
  static ContentRegion fromCountryCode(String? countryCode) {
    return countryCode?.toUpperCase() == 'CN'
        ? ContentRegion.mainlandChina
        : ContentRegion.international;
  }

  static ContentRegion resolve(
    RegionPreference preference,
    ContentRegion deviceRegion,
  ) => switch (preference) {
    RegionPreference.automatic => deviceRegion,
    RegionPreference.mainlandChina => ContentRegion.mainlandChina,
    RegionPreference.international => ContentRegion.international,
  };
}
