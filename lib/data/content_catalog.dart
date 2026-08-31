import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/stillow_models.dart';

class ContentCatalog {
  ContentCatalog({
    required this.schemaVersion,
    required List<GuidedSession> items,
    List<GuidedSession> studyItems = const [],
    List<GuidedSession> candidates = const [],
  }) : items = List.unmodifiable(items),
       studyItems = List.unmodifiable(studyItems),
       candidates = List.unmodifiable(candidates),
       _localizations = const {};

  ContentCatalog._({
    required this.schemaVersion,
    required List<GuidedSession> items,
    required List<GuidedSession> studyItems,
    required List<GuidedSession> candidates,
    required Map<String, _CatalogLocale> localizations,
  }) : items = List.unmodifiable(items),
       studyItems = List.unmodifiable(studyItems),
       candidates = List.unmodifiable(candidates),
       _localizations = Map.unmodifiable(localizations);

  final int schemaVersion;
  final List<GuidedSession> items;
  final List<GuidedSession> studyItems;
  final List<GuidedSession> candidates;
  final Map<String, _CatalogLocale> _localizations;

  static Future<ContentCatalog> loadAsset({
    String path = 'assets/content/audio_catalog.json',
    String studyPath = 'assets/content/study_drowsy_catalog.json',
    String candidatePath = 'assets/content/audio_candidates.json',
    String localizationPath = 'assets/content/content_localizations.json',
  }) async {
    final jsonTexts = await Future.wait([
      rootBundle.loadString(path),
      rootBundle.loadString(studyPath),
      rootBundle.loadString(candidatePath),
      rootBundle.loadString(localizationPath),
    ]);
    return ContentCatalog.fromJsonString(
      jsonTexts[0],
      studyJsonText: jsonTexts[1],
      candidateJsonText: jsonTexts[2],
      localizationJsonText: jsonTexts[3],
    );
  }

  factory ContentCatalog.fromJsonString(
    String jsonText, {
    String? studyJsonText,
    String? candidateJsonText,
    String? localizationJsonText,
  }) {
    final root = jsonDecode(jsonText) as Map<String, dynamic>;
    final rawItems = root['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map((item) => _sessionFromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    if (items.isEmpty) {
      throw const FormatException('音频素材目录不能为空');
    }

    final studyItems = studyJsonText == null
        ? const <GuidedSession>[]
        : _regularSessionsFromJson(studyJsonText);
    final candidates = candidateJsonText == null
        ? const <GuidedSession>[]
        : _candidateSessionsFromJson(candidateJsonText);
    final localizations = localizationJsonText == null
        ? const <String, _CatalogLocale>{}
        : _catalogLocalizationsFromJson(localizationJsonText);

    return ContentCatalog._(
      schemaVersion: root['schemaVersion'] as int? ?? 1,
      items: items,
      studyItems: studyItems,
      candidates: candidates,
      localizations: localizations,
    );
  }

  ContentCatalog forExperience({
    required String interfaceLanguageCode,
    required AudioLanguagePreference audioLanguagePreference,
  }) {
    final interfaceLanguage = interfaceLanguageCode == 'zh' ? 'zh' : 'en';
    final spokenLanguage = switch (audioLanguagePreference) {
      AudioLanguagePreference.automatic => interfaceLanguage,
      AudioLanguagePreference.chinese => 'zh',
      AudioLanguagePreference.english => 'en',
      AudioLanguagePreference.any => null,
    };
    final locale = _localizations[interfaceLanguage];

    List<GuidedSession> prepare(Iterable<GuidedSession> sessions) => sessions
        .where((session) => _matchesSpokenLanguage(session, spokenLanguage))
        .map((session) => _localizedSession(session, locale))
        .toList(growable: false);

    return ContentCatalog._(
      schemaVersion: schemaVersion,
      items: prepare(items),
      studyItems: prepare(studyItems),
      candidates: prepare(candidates),
      localizations: _localizations,
    );
  }

  static bool _matchesSpokenLanguage(
    GuidedSession session,
    String? spokenLanguage,
  ) {
    if (spokenLanguage == null || session.languageCode == 'zxx') return true;
    if (spokenLanguage == 'zh') {
      return session.languageCode.toLowerCase().startsWith('zh');
    }
    return session.languageCode.toLowerCase() == spokenLanguage;
  }

  static GuidedSession _localizedSession(
    GuidedSession session,
    _CatalogLocale? locale,
  ) {
    if (locale == null) return session;
    final translated = locale.sessions[session.id];
    if (translated != null) {
      return session.withLocalizedText(
        title: translated.title,
        subtitle: translated.subtitle,
        shortLabel: translated.shortLabel,
      );
    }
    if (!session.isCandidate) return session;

    final copy = locale.candidate;
    final contentLabel = switch (session.kind) {
      SessionKind.lecture => copy.spokenKnowledge,
      SessionKind.music => copy.music,
      _ => copy.soundscape,
    };
    final duration = _durationLabelForLocale(
      session.durationSeconds,
      fallback: copy.durationUnknown,
    );
    return session.withLocalizedText(
      title: session.sourceTitle,
      subtitle: '$contentLabel · $duration · ${copy.awaitingReview}',
      shortLabel: '${copy.candidatePrefix} $contentLabel · $duration',
    );
  }

  static String _durationLabelForLocale(
    int? seconds, {
    required String fallback,
  }) {
    if (seconds == null || seconds <= 0) return fallback;
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours hr' : '$hours hr $rest min';
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

  List<GuidedSession> studyDrowsyFor(ContentRegion region) {
    final result =
        studyItems
            .where(
              (item) =>
                  item.isPlaybackEligible &&
                  item.regions.contains(region) &&
                  item.tags.contains('study_drowsy'),
            )
            .toList(growable: false)
          ..sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

  List<GuidedSession> spokenFor(ContentRegion region) => sessionsFor(region)
      .where(
        (session) => const {
          SessionKind.guidedVoice,
          SessionKind.narrative,
          SessionKind.lecture,
        }.contains(session.kind),
      )
      .toList();

  List<GuidedSession> candidateSessionsFor(ContentRegion region) {
    final result =
        candidates
            .where(
              (item) =>
                  item.isPlaybackEligible && item.regions.contains(region),
            )
            .toList(growable: false)
          ..sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

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

  bool get hasGuidedRelaxation => items.any(
    (session) => session.isPlaybackEligible && session.tags.contains('guided'),
  );

  GuidedSession? findById(String? id) {
    if (id == null) return null;
    for (final session in [...items, ...studyItems, ...candidates]) {
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
    final available = [
      ...sessionsFor(region),
      ..._personalizedStudyFor(profile, region),
    ];
    if (available.isEmpty) {
      throw StateError('当前地区没有可用素材');
    }

    final goal = _goalTag(profile, state);
    final ranked =
        available
            .map(
              (session) => (
                session: session,
                score: _score(session, profile, goal, SleepUseContext.bedtime),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));
    return ranked.first.session;
  }

  List<GuidedSession> _personalizedStudyFor(
    UserProfile profile,
    ContentRegion region,
  ) {
    final affinity = profile.tagAffinities['study_drowsy'] ?? 0;
    if (affinity < 4) return const [];
    return studyDrowsyFor(region)
        .where((session) => (profile.sessionAffinities[session.id] ?? 0) >= 6)
        .toList(growable: false);
  }

  GuidedSession recommendNightRescue(
    UserProfile profile,
    ContentRegion region,
  ) {
    final allowMasking =
        profile.supportNeed == SupportNeed.maskNoise ||
        profile.soundPreference == SoundPreference.nature;
    final allNightSessions = ambientFor(
      region,
    ).where((session) => session.tags.contains('night_awake')).toList();
    final preferredNightSessions = allNightSessions
        .where(
          (session) =>
              allowMasking || !session.tags.contains('role_masking_only'),
        )
        .toList(growable: false);
    final nightSessions = preferredNightSessions.isNotEmpty
        ? preferredNightSessions
        : allNightSessions;
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
                ),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));
    return ranked.first.session;
  }

  static List<GuidedSession> _regularSessionsFromJson(String jsonText) {
    final root = jsonDecode(jsonText) as Map<String, dynamic>;
    final rawItems = root['items'] as List<dynamic>? ?? const [];
    return rawItems
        .map((item) => _sessionFromJson(item as Map<String, dynamic>))
        .toList(growable: false);
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

  static List<GuidedSession> _candidateSessionsFromJson(String jsonText) {
    final root = jsonDecode(jsonText) as Map<String, dynamic>;
    final rawItems = root['items'] as List<dynamic>? ?? const [];
    return rawItems
        .map((item) => _candidateSessionFromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static GuidedSession _candidateSessionFromJson(Map<String, dynamic> json) {
    final rawKind = _requiredString(json, 'kind');
    final title = _requiredString(json, 'title');
    final kind = _candidateKind(rawKind, title);
    final durationSeconds = json['durationSeconds'] as int?;
    final durationLabel = _durationLabel(durationSeconds);
    final provider = _requiredString(json, 'provider');
    final contentLabel = switch (rawKind) {
      'spokenKnowledge' => '中文朗读',
      'soundscape' => '环境声',
      _ => '轻音乐',
    };

    return GuidedSession(
      id: _requiredString(json, 'id'),
      title: _compactTitle(title),
      subtitle: '$contentLabel · ${durationLabel ?? '时长待确认'} · 待试听',
      shortLabel:
          '候选$contentLabel${durationLabel == null ? '' : ' · $durationLabel'}',
      kind: kind,
      tags: _candidateTags(rawKind, kind),
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
      provider: provider,
      playbackType: PlaybackType.directAudio,
      playbackUrl: Uri.parse(_requiredString(json, 'playbackUrl')),
      adFree: json['adFreeSource'] as bool? ?? false,
      rightsStatus: _requiredString(json, 'rightsStatus'),
      sourcePage: Uri.parse(_requiredString(json, 'sourcePage')),
      sourceTitle: title,
      creator: _requiredString(json, 'creator'),
      licenseName: _requiredString(json, 'licenseName'),
      licenseUrl: Uri.parse(_requiredString(json, 'licenseUrl')),
      loop: json['loopCandidate'] as bool? ?? false,
      priority: json['selectionScore'] as int? ?? 0,
      enabled: true,
      isCandidate: true,
      languageCode: json['languageCode'] as String? ?? 'zxx',
      durationSeconds: durationSeconds,
    );
  }

  static SessionKind _candidateKind(String rawKind, String title) {
    if (rawKind == 'spokenKnowledge') return SessionKind.lecture;
    if (rawKind == 'music') return SessionKind.music;
    final lowered = title.toLowerCase();
    if (lowered.contains('rain') || lowered.contains('雨')) {
      return SessionKind.rain;
    }
    if (lowered.contains('ocean') ||
        lowered.contains('wave') ||
        lowered.contains('海')) {
      return SessionKind.ocean;
    }
    if (lowered.contains('forest') ||
        lowered.contains('bird') ||
        lowered.contains('森林')) {
      return SessionKind.forest;
    }
    return SessionKind.brownNoise;
  }

  static Set<String> _candidateTags(String rawKind, SessionKind kind) {
    if (rawKind == 'spokenKnowledge') {
      return const {
        'candidate',
        'gentle_company',
        'spoken_content',
        'lecture',
        'low_stimulus',
        'review_spoken',
      };
    }
    if (rawKind == 'music') {
      return const {
        'candidate',
        'music',
        'ambient',
        'low_stimulus',
        'review_music',
      };
    }
    return {
      'candidate',
      'mask_noise',
      'nature',
      'ambient',
      'low_stimulus',
      'review_masking',
      'kind:${kind.name}',
    };
  }

  static String? _durationLabel(int? durationSeconds) {
    if (durationSeconds == null || durationSeconds <= 0) return null;
    final minutes = (durationSeconds / 60).round();
    return '约 $minutes 分钟';
  }

  static String _compactTitle(String title) {
    final runes = title.runes.toList(growable: false);
    if (runes.length <= 56) return title;
    return '${String.fromCharCodes(runes.take(56))}…';
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
  ) {
    var score = session.priority;
    if (session.tags.contains(goal)) score += 100;

    final trialAlignedMusic = session.tags.contains('role_trial_aligned_music');
    final guidedRelaxation = session.tags.contains('role_guided_relaxation');
    final supportingMusic = session.tags.contains('role_supporting_music');
    final breathingPacer = session.tags.contains('role_breathing_pacer');
    final comfortOnly = session.tags.contains('role_comfort_only');
    final maskingOnly = session.tags.contains('role_masking_only');
    final studyDrowsy = session.tags.contains('study_drowsy');

    if (trialAlignedMusic &&
        const {
          'quiet_mind',
          'relax_body',
          'not_sleepy',
          'sleep_pressure',
          'night_awake',
        }.contains(goal)) {
      score += 30;
    }
    if (guidedRelaxation && const {'quiet_mind', 'relax_body'}.contains(goal)) {
      score += 30;
    }
    if (supportingMusic &&
        const {
          'quiet_mind',
          'not_sleepy',
          'sleep_pressure',
          'night_awake',
        }.contains(goal)) {
      score += 10;
    }
    if (breathingPacer && const {'quiet_mind', 'relax_body'}.contains(goal)) {
      score += 20;
    }

    if (studyDrowsy) {
      final affinity = profile.tagAffinities['study_drowsy'] ?? 0;
      score += affinity < 4 ? -300 : 110 + affinity * 12;
    } else if (comfortOnly) {
      score += goal == 'gentle_company' ? 50 : -90;
    }
    if (maskingOnly) {
      final maskingPreferred =
          goal == 'mask_noise' ||
          (goal == 'night_awake' &&
              (profile.supportNeed == SupportNeed.maskNoise ||
                  profile.soundPreference == SoundPreference.nature));
      score += maskingPreferred ? 40 : -80;
    }
    if (session.tags.contains('short_loop_risk')) score -= 20;
    if (session.tags.contains('needs_long_form_master')) score -= 5;

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

Map<String, _CatalogLocale> _catalogLocalizationsFromJson(String text) {
  final root = jsonDecode(text) as Map<String, dynamic>;
  final locales = root['locales'] as Map<String, dynamic>? ?? const {};
  return locales.map(
    (code, value) =>
        MapEntry(code, _CatalogLocale.fromJson(value as Map<String, dynamic>)),
  );
}

String _localizedRequiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing localized content field: $key');
  }
  return value;
}

class _CatalogLocale {
  const _CatalogLocale({required this.sessions, required this.candidate});

  final Map<String, _LocalizedSessionText> sessions;
  final _CandidateCopy candidate;

  factory _CatalogLocale.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'] as Map<String, dynamic>? ?? const {};
    return _CatalogLocale(
      sessions: Map.unmodifiable(
        rawSessions.map(
          (id, value) => MapEntry(
            id,
            _LocalizedSessionText.fromJson(value as Map<String, dynamic>),
          ),
        ),
      ),
      candidate: _CandidateCopy.fromJson(
        json['candidate'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class _LocalizedSessionText {
  const _LocalizedSessionText({
    required this.title,
    required this.subtitle,
    required this.shortLabel,
  });

  final String title;
  final String subtitle;
  final String shortLabel;

  factory _LocalizedSessionText.fromJson(Map<String, dynamic> json) =>
      _LocalizedSessionText(
        title: _localizedRequiredString(json, 'title'),
        subtitle: _localizedRequiredString(json, 'subtitle'),
        shortLabel: _localizedRequiredString(json, 'shortLabel'),
      );
}

class _CandidateCopy {
  const _CandidateCopy({
    required this.spokenKnowledge,
    required this.soundscape,
    required this.music,
    required this.durationUnknown,
    required this.awaitingReview,
    required this.candidatePrefix,
  });

  final String spokenKnowledge;
  final String soundscape;
  final String music;
  final String durationUnknown;
  final String awaitingReview;
  final String candidatePrefix;

  factory _CandidateCopy.fromJson(Map<String, dynamic> json) => _CandidateCopy(
    spokenKnowledge: _localizedRequiredString(json, 'spokenKnowledge'),
    soundscape: _localizedRequiredString(json, 'soundscape'),
    music: _localizedRequiredString(json, 'music'),
    durationUnknown: _localizedRequiredString(json, 'durationUnknown'),
    awaitingReview: _localizedRequiredString(json, 'awaitingReview'),
    candidatePrefix: _localizedRequiredString(json, 'candidatePrefix'),
  );
}
