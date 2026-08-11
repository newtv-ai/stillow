import 'package:flutter/material.dart';

enum SupportNeed { quietMind, relaxBody, maskNoise, gentleCompany }

enum SoundPreference { softVoice, familiarMusic, nature, minimal }

enum GuidancePreference { stepByStep, occasional, ambientOnly }

enum NightState { busyMind, tenseBody, noisyRoom, unsure }

enum SessionFeedback { comfortable, noDifference, notForMe }

enum ContentRegion { mainlandChina, international }

enum PlaybackType { assetAudio, directAudio, platformPage }

enum SessionKind {
  guidedVoice,
  rain,
  brownNoise,
  ocean,
  forest,
  music,
  lecture,
}

class UserProfile {
  const UserProfile({
    this.onboardingComplete = false,
    this.supportNeed,
    this.soundPreference,
    this.guidancePreference,
    this.lastSessionId,
    this.pendingFeedback = false,
    this.lastFeedback,
    this.sessionCount = 0,
    this.noHelpCount = 0,
  });

  final bool onboardingComplete;
  final SupportNeed? supportNeed;
  final SoundPreference? soundPreference;
  final GuidancePreference? guidancePreference;
  final String? lastSessionId;
  final bool pendingFeedback;
  final SessionFeedback? lastFeedback;
  final int sessionCount;
  final int noHelpCount;

  UserProfile copyWith({
    bool? onboardingComplete,
    SupportNeed? supportNeed,
    SoundPreference? soundPreference,
    GuidancePreference? guidancePreference,
    String? lastSessionId,
    bool? pendingFeedback,
    SessionFeedback? lastFeedback,
    int? sessionCount,
    int? noHelpCount,
  }) {
    return UserProfile(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      supportNeed: supportNeed ?? this.supportNeed,
      soundPreference: soundPreference ?? this.soundPreference,
      guidancePreference: guidancePreference ?? this.guidancePreference,
      lastSessionId: lastSessionId ?? this.lastSessionId,
      pendingFeedback: pendingFeedback ?? this.pendingFeedback,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      sessionCount: sessionCount ?? this.sessionCount,
      noHelpCount: noHelpCount ?? this.noHelpCount,
    );
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
  final String? assetPath;
  final String? sha256;
  final int? durationSeconds;

  bool get isInAppAudio =>
      playbackType == PlaybackType.assetAudio ||
      playbackType == PlaybackType.directAudio;

  bool get isPlaybackEligible =>
      enabled &&
      adFree &&
      (rightsStatus == 'publicDomain' || rightsStatus == 'cc0') &&
      isInAppAudio;

  String get providerLabel => switch (provider) {
    'bilibili' => '哔哩哔哩',
    'youtube' => 'YouTube',
    'internetArchive' => 'Internet Archive',
    'librivox' => 'LibriVox',
    _ => provider,
  };

  IconData get icon => switch (kind) {
    SessionKind.guidedVoice => Icons.spa_outlined,
    SessionKind.rain => Icons.water_drop_outlined,
    SessionKind.brownNoise => Icons.graphic_eq_rounded,
    SessionKind.ocean => Icons.waves_rounded,
    SessionKind.forest => Icons.forest_outlined,
    SessionKind.music => Icons.music_note_rounded,
    SessionKind.lecture => Icons.school_outlined,
  };
}
