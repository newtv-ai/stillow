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

enum AppLanguagePreference { system, simplifiedChinese, english }

enum AudioLanguagePreference { automatic, chinese, english, any }

enum SleepUseContext { bedtime, nightAwake }

enum PlaybackType { assetAudio, directAudio }

enum PlaybackOrigin { catalog, user }

enum UserSoundSourceKind { fileCopy, devicePath }

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
    this.appLanguagePreference = AppLanguagePreference.system,
    this.audioLanguagePreference = AudioLanguagePreference.automatic,
    this.nightPresetSessionId,
    this.tonightDefaultUserSoundId,
    this.nightPresetUserSoundId,
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
  final AppLanguagePreference appLanguagePreference;
  final AudioLanguagePreference audioLanguagePreference;
  final String? nightPresetSessionId;
  final String? tonightDefaultUserSoundId;
  final String? nightPresetUserSoundId;

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
    AppLanguagePreference? appLanguagePreference,
    AudioLanguagePreference? audioLanguagePreference,
    String? nightPresetSessionId,
    bool clearNightPresetSessionId = false,
    String? tonightDefaultUserSoundId,
    bool clearTonightDefaultUserSoundId = false,
    String? nightPresetUserSoundId,
    bool clearNightPresetUserSoundId = false,
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
      appLanguagePreference:
          appLanguagePreference ?? this.appLanguagePreference,
      audioLanguagePreference:
          audioLanguagePreference ?? this.audioLanguagePreference,
      nightPresetSessionId: clearNightPresetSessionId
          ? null
          : nightPresetSessionId ?? this.nightPresetSessionId,
      tonightDefaultUserSoundId: clearTonightDefaultUserSoundId
          ? null
          : tonightDefaultUserSoundId ?? this.tonightDefaultUserSoundId,
      nightPresetUserSoundId: clearNightPresetUserSoundId
          ? null
          : nightPresetUserSoundId ?? this.nightPresetUserSoundId,
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

  GuidedSession withLocalizedText({
    required String title,
    required String subtitle,
    required String shortLabel,
  }) => GuidedSession(
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
    localFilePath: localFilePath,
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

class UserSound {
  const UserSound({
    required this.id,
    required this.title,
    required this.sourceKind,
    required this.originalFileName,
    required this.loop,
    required this.attenuateLoops,
    required this.createdAt,
    this.relativePath = '',
    this.sourcePath,
    this.accessBookmark,
    this.defaultTimerMinutes = 30,
    this.durationSeconds,
    this.localFilePath,
  });

  final String id;
  final String title;
  final UserSoundSourceKind sourceKind;
  final String relativePath;
  final String? sourcePath;
  final String? accessBookmark;
  final String originalFileName;
  final bool loop;
  final bool attenuateLoops;
  final int? defaultTimerMinutes;
  final DateTime createdAt;
  final int? durationSeconds;
  final String? localFilePath;

  Uri? get playbackUri {
    final path = sourcePath;
    if (path == null || !path.startsWith('content:')) return null;
    return Uri.tryParse(path);
  }

  UserSound copyWith({
    String? title,
    bool? loop,
    bool? attenuateLoops,
    Object? defaultTimerMinutes = _unsetValue,
    int? durationSeconds,
    String? localFilePath,
  }) => UserSound(
    id: id,
    title: title ?? this.title,
    sourceKind: sourceKind,
    relativePath: relativePath,
    sourcePath: sourcePath,
    accessBookmark: accessBookmark,
    originalFileName: originalFileName,
    loop: loop ?? this.loop,
    attenuateLoops: attenuateLoops ?? this.attenuateLoops,
    defaultTimerMinutes: identical(defaultTimerMinutes, _unsetValue)
        ? this.defaultTimerMinutes
        : defaultTimerMinutes as int?,
    createdAt: createdAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    localFilePath: localFilePath ?? this.localFilePath,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'sourceKind': sourceKind.name,
    'relativePath': relativePath,
    'sourcePath': sourcePath,
    'accessBookmark': accessBookmark,
    'originalFileName': originalFileName,
    'loop': loop,
    'attenuateLoops': attenuateLoops,
    'defaultTimerMinutes': defaultTimerMinutes,
    'createdAt': createdAt.toIso8601String(),
    'durationSeconds': durationSeconds,
  };

  static UserSound? tryFromJson(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final id = json['id'];
    final title = json['title'];
    final relativePathValue = json['relativePath'];
    final sourcePathValue = json['sourcePath'];
    final accessBookmarkValue = json['accessBookmark'];
    final originalFileName = json['originalFileName'];
    final createdAtValue = json['createdAt'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;
    final sourceKindValue = json['sourceKind'];
    final sourceKind = sourceKindValue == null
        ? UserSoundSourceKind.fileCopy
        : sourceKindValue is String
        ? _enumByName(UserSoundSourceKind.values, sourceKindValue)
        : null;
    final timerValue = json['defaultTimerMinutes'];
    final durationValue = json['durationSeconds'];
    if (id is! String ||
        id.isEmpty ||
        title is! String ||
        title.trim().isEmpty ||
        originalFileName is! String ||
        originalFileName.isEmpty ||
        createdAt == null ||
        sourceKind == null ||
        timerValue != null && timerValue is! num ||
        durationValue != null && durationValue is! num ||
        accessBookmarkValue != null && accessBookmarkValue is! String) {
      return null;
    }
    final relativePath = relativePathValue is String ? relativePathValue : '';
    final sourcePath = sourcePathValue is String ? sourcePathValue : null;
    if (sourceKind == UserSoundSourceKind.fileCopy && relativePath.isEmpty) {
      return null;
    }
    if (sourceKind == UserSoundSourceKind.devicePath &&
        (sourcePath == null || sourcePath.isEmpty)) {
      return null;
    }
    final timer = !json.containsKey('defaultTimerMinutes')
        ? 30
        : timerValue == null
        ? null
        : (timerValue as num).toInt();
    if (timer != null && !const {15, 30, 45, 60}.contains(timer)) return null;
    return UserSound(
      id: id,
      title: title.trim(),
      sourceKind: sourceKind,
      relativePath: relativePath,
      sourcePath: sourcePath,
      accessBookmark: accessBookmarkValue is String
          ? accessBookmarkValue
          : null,
      originalFileName: originalFileName,
      loop: json['loop'] == true,
      attenuateLoops: json['attenuateLoops'] == true,
      defaultTimerMinutes: timer,
      createdAt: createdAt,
      durationSeconds: durationValue == null
          ? null
          : (durationValue as num).toInt().clamp(0, 86400),
    );
  }
}

class PlaybackItem {
  const PlaybackItem._({
    required this.origin,
    required this.guidedSession,
    required this.userSound,
    required this.userSubtitle,
    required this.userShortLabel,
    required this.userCreatorLabel,
  });

  factory PlaybackItem.fromGuidedSession(GuidedSession session) =>
      PlaybackItem._(
        origin: PlaybackOrigin.catalog,
        guidedSession: session,
        userSound: null,
        userSubtitle: null,
        userShortLabel: null,
        userCreatorLabel: null,
      );

  factory PlaybackItem.fromUserSound(
    UserSound sound, {
    required String subtitle,
    required String shortLabel,
    required String creatorLabel,
  }) => PlaybackItem._(
    origin: PlaybackOrigin.user,
    guidedSession: null,
    userSound: sound,
    userSubtitle: subtitle,
    userShortLabel: shortLabel,
    userCreatorLabel: creatorLabel,
  );

  final PlaybackOrigin origin;
  final GuidedSession? guidedSession;
  final UserSound? userSound;
  final String? userSubtitle;
  final String? userShortLabel;
  final String? userCreatorLabel;

  bool get isUserSound => origin == PlaybackOrigin.user;
  String get id => guidedSession?.id ?? 'user:${userSound!.id}';
  String get title => guidedSession?.title ?? userSound!.title;
  String get subtitle => guidedSession?.subtitle ?? userSubtitle!;
  String get shortLabel => guidedSession?.shortLabel ?? userShortLabel!;
  String get creator => guidedSession?.creator ?? userCreatorLabel!;
  bool get loop => guidedSession?.loop ?? userSound!.loop;
  bool get attenuateLoops => guidedSession != null
      ? guidedSession!.loop && guidedSession!.kind == SessionKind.music
      : userSound!.loop && userSound!.attenuateLoops;
  bool get isCandidate => guidedSession?.isCandidate ?? false;
  String? get localFilePath =>
      guidedSession?.localFilePath ?? userSound?.localFilePath;
  String? get assetPath => guidedSession?.assetPath;
  Uri? get playbackUrl => guidedSession?.playbackUrl ?? userSound?.playbackUri;
  PlaybackType? get playbackType => guidedSession?.playbackType;
  int? get durationSeconds =>
      guidedSession?.durationSeconds ?? userSound?.durationSeconds;
  IconData get icon => guidedSession?.icon ?? Icons.audio_file_rounded;
}

const Object _unsetValue = Object();

T? _enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
