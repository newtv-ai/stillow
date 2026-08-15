import 'package:flutter/material.dart';

enum SupportNeed {
  quietMind,
  notSleepy,
  sleepPressure,
  relaxBody,
  maskNoise,
  nightAwake,
  gentleCompany,
}

enum SoundPreference { softVoice, familiarMusic, nature, minimal }

enum GuidancePreference { stepByStep, occasional, ambientOnly }

enum NightState {
  busyMind,
  notSleepy,
  sleepPressure,
  tenseBody,
  noisyRoom,
  nightAwake,
  unsure,
}

enum SessionFeedback { comfortable, noDifference, notForMe }

enum ContentRegion { mainlandChina, international }

enum RegionPreference { automatic, mainlandChina, international }

enum SleepUseContext { bedtime, nightAwake }

enum PlaybackType { assetAudio, directAudio }

enum SessionKind {
  guidedVoice,
  rain,
  brownNoise,
  ocean,
  forest,
  music,
  narrative,
  lecture,
  breathingPacer,
}

class UserProfile {
  const UserProfile({
    this.onboardingComplete = false,
    this.supportNeed,
    this.soundPreference,
    this.guidancePreference,
    this.lastSessionId,
    this.lastUseContext = SleepUseContext.bedtime,
    this.pendingFeedback = false,
    this.lastFeedback,
    this.noHelpCount = 0,
    this.tagAffinities = const {},
    this.sessionAffinities = const {},
    this.favoriteSessionIds = const {},
    this.regionPreference = RegionPreference.automatic,
    this.nightPresetSessionId,
  });

  final bool onboardingComplete;
  final SupportNeed? supportNeed;
  final SoundPreference? soundPreference;
  final GuidancePreference? guidancePreference;
  final String? lastSessionId;
  final SleepUseContext lastUseContext;
  final bool pendingFeedback;
  final SessionFeedback? lastFeedback;
  final int noHelpCount;
  final Map<String, int> tagAffinities;
  final Map<String, int> sessionAffinities;
  final Set<String> favoriteSessionIds;
  final RegionPreference regionPreference;
  final String? nightPresetSessionId;

  UserProfile copyWith({
    bool? onboardingComplete,
    SupportNeed? supportNeed,
    SoundPreference? soundPreference,
    GuidancePreference? guidancePreference,
    String? lastSessionId,
    SleepUseContext? lastUseContext,
    bool? pendingFeedback,
    SessionFeedback? lastFeedback,
    int? noHelpCount,
    Map<String, int>? tagAffinities,
    Map<String, int>? sessionAffinities,
    Set<String>? favoriteSessionIds,
    RegionPreference? regionPreference,
    String? nightPresetSessionId,
  }) {
    return UserProfile(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      supportNeed: supportNeed ?? this.supportNeed,
      soundPreference: soundPreference ?? this.soundPreference,
      guidancePreference: guidancePreference ?? this.guidancePreference,
      lastSessionId: lastSessionId ?? this.lastSessionId,
      lastUseContext: lastUseContext ?? this.lastUseContext,
      pendingFeedback: pendingFeedback ?? this.pendingFeedback,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      noHelpCount: noHelpCount ?? this.noHelpCount,
      tagAffinities: tagAffinities ?? this.tagAffinities,
      sessionAffinities: sessionAffinities ?? this.sessionAffinities,
      favoriteSessionIds: favoriteSessionIds ?? this.favoriteSessionIds,
      regionPreference: regionPreference ?? this.regionPreference,
      nightPresetSessionId: nightPresetSessionId ?? this.nightPresetSessionId,
    );
  }

  UserProfile learnFrom(
    GuidedSession session,
    SessionFeedback feedback, {
    SleepUseContext context = SleepUseContext.bedtime,
  }) {
    final tagDelta = switch (feedback) {
      SessionFeedback.comfortable => 2,
      SessionFeedback.noDifference => -1,
      SessionFeedback.notForMe => -2,
    };
    final sessionDelta = switch (feedback) {
      SessionFeedback.comfortable => 3,
      SessionFeedback.noDifference => -1,
      SessionFeedback.notForMe => -4,
    };

    final learnedTags = <String>{
      'kind:${session.kind.name}',
      ...session.tags.where(_isLearnableTag),
    };
    final nextTagAffinities = Map<String, int>.from(tagAffinities);
    for (final tag in learnedTags) {
      nextTagAffinities[tag] = ((nextTagAffinities[tag] ?? 0) + tagDelta)
          .clamp(-8, 8)
          .toInt();
    }
    final contextualKind = 'context:${context.name}:kind:${session.kind.name}';
    nextTagAffinities[contextualKind] =
        ((nextTagAffinities[contextualKind] ?? 0) + tagDelta)
            .clamp(-8, 8)
            .toInt();

    final nextSessionAffinities = Map<String, int>.from(sessionAffinities);
    nextSessionAffinities[session.id] =
        ((nextSessionAffinities[session.id] ?? 0) + sessionDelta)
            .clamp(-12, 12)
            .toInt();

    return copyWith(
      tagAffinities: Map.unmodifiable(nextTagAffinities),
      sessionAffinities: Map.unmodifiable(nextSessionAffinities),
    );
  }

  static bool _isLearnableTag(String tag) {
    if (tag.startsWith('role_') ||
        tag.startsWith('review_') ||
        tag.startsWith('needs_') ||
        tag.endsWith('_screened')) {
      return false;
    }
    return !const {
      'quiet_mind',
      'relax_body',
      'mask_noise',
      'gentle_company',
      'night_awake',
      'not_sleepy',
      'sleep_pressure',
      'candidate',
      'low_stimulus',
      'instrumental',
      'short_loop_risk',
      'long_form_master',
    }.contains(tag);
  }
}

class GuidedSession {
  const GuidedSession({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.shortLabel,
    required this.kind,
    required this.tags,
    required this.regions,
    required this.provider,
    required this.playbackType,
    required this.playbackUrl,
    required this.adFree,
    required this.rightsStatus,
    required this.sourcePage,
    required this.sourceTitle,
    required this.creator,
    required this.licenseName,
    required this.licenseUrl,
    required this.loop,
    required this.priority,
    required this.enabled,
    this.isCandidate = false,
    this.languageCode = 'zxx',
    this.localFilePath,
    this.assetPath,
    this.sha256,
    this.durationSeconds,
  });

  final String id;
  final String title;
  final String subtitle;
  final String shortLabel;
  final SessionKind kind;
  final Set<String> tags;
  final Set<ContentRegion> regions;
  final String provider;
  final PlaybackType playbackType;
  final Uri playbackUrl;
  final bool adFree;
  final String rightsStatus;
  final Uri sourcePage;
  final String sourceTitle;
  final String creator;
  final String licenseName;
  final Uri licenseUrl;
  final bool loop;
  final int priority;
  final bool enabled;
  final bool isCandidate;
  final String languageCode;
  final String? localFilePath;
  final String? assetPath;
  final String? sha256;
  final int? durationSeconds;

  bool get isInAppAudio =>
      playbackType == PlaybackType.assetAudio ||
      playbackType == PlaybackType.directAudio;

  bool get isAvailableOffline =>
      playbackType == PlaybackType.assetAudio || localFilePath != null;

  bool get isPlaybackEligible =>
      enabled &&
      adFree &&
      const {
        'publicDomain',
        'cc0',
        'ccBy',
        'ccBySa',
        'usGovernmentPublicDomain',
      }.contains(rightsStatus) &&
      isInAppAudio;

  GuidedSession withLocalFile(String path) => GuidedSession(
    id: id,
    title: title,
    subtitle: subtitle,
    shortLabel: shortLabel,
    kind: kind,
    tags: tags,
    regions: regions,
    provider: provider,
    playbackType: playbackType,
    playbackUrl: playbackUrl,
    adFree: adFree,
    rightsStatus: rightsStatus,
    sourcePage: sourcePage,
    sourceTitle: sourceTitle,
    creator: creator,
    licenseName: licenseName,
    licenseUrl: licenseUrl,
    loop: loop,
    priority: priority,
    enabled: enabled,
    isCandidate: isCandidate,
    languageCode: languageCode,
    localFilePath: path,
    assetPath: assetPath,
    sha256: sha256,
    durationSeconds: durationSeconds,
  );

  String get providerLabel => switch (provider) {
    'internetArchive' => 'Internet Archive',
    'librivox' => 'LibriVox',
    'openGameArt' => 'OpenGameArt',
    'wikimediaCommons' => 'Wikimedia Commons',
    'usDepartmentVeteransAffairs' => '美国退伍军人事务部',
    _ => provider,
  };

  IconData get icon => switch (kind) {
    SessionKind.guidedVoice => Icons.spa_outlined,
    SessionKind.rain => Icons.water_drop_outlined,
    SessionKind.brownNoise => Icons.graphic_eq_rounded,
    SessionKind.ocean => Icons.waves_rounded,
    SessionKind.forest => Icons.forest_outlined,
    SessionKind.music => Icons.music_note_rounded,
    SessionKind.narrative => Icons.auto_stories_outlined,
    SessionKind.lecture => Icons.school_outlined,
    SessionKind.breathingPacer => Icons.air_rounded,
  };
}
