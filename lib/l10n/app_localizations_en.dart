// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stillow';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get finish => 'End';

  @override
  String get continueLabel => 'Continue';

  @override
  String get keepForNow => 'Keep it';

  @override
  String get clear => 'Clear';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get onboardingSkip => 'Listen first';

  @override
  String get onboardingKeep => 'Keep current choices';

  @override
  String get onboardingTryTonight => 'Try this tonight';

  @override
  String get onboardingNeedTitle =>
      'What kind of support would feel best tonight?';

  @override
  String get onboardingNeedSubtitle =>
      'Choose the one that feels closest right now.';

  @override
  String get needQuietMind => 'My thoughts keep going';

  @override
  String get needNotSleepy => 'My mind is quiet, but I am not sleepy';

  @override
  String get needSleepPressure => 'Trying to sleep makes me more alert';

  @override
  String get needRelaxBody => 'I want my body to loosen up';

  @override
  String get needMaskNoise => 'I want the room to feel quieter';

  @override
  String get needNightAwake =>
      'I woke during the night and cannot settle again';

  @override
  String get needGentleCompany =>
      'I am not sure; I would just like some company';

  @override
  String get onboardingSoundTitle => 'What kind of sound feels comfortable?';

  @override
  String get onboardingSoundSubtitle =>
      'Pick what sounds good now. You can change it anytime.';

  @override
  String get soundSoftVoice => 'A gentle voice or calm reading';

  @override
  String get soundFamiliarMusic => 'Familiar, steady music';

  @override
  String get soundNature => 'Rain, wind, or other ambient sound';

  @override
  String get soundMinimal => 'Mostly quiet, with very little guidance';

  @override
  String get onboardingGuidanceTitle => 'How much guidance do you prefer?';

  @override
  String get onboardingGuidanceSubtitle =>
      'Choose the level of company that feels right.';

  @override
  String get guidanceStepByStep => 'Guide me through relaxing';

  @override
  String get guidanceOccasional => 'A gentle cue now and then';

  @override
  String get guidanceAmbientOnly => 'Just sound, with no guidance';

  @override
  String get homeSettingsTooltip => 'Settings and about Stillow';

  @override
  String get homeGreeting => 'A slower\nevening.';

  @override
  String get homePrompt => 'Choose a sound that feels right just now.';

  @override
  String get homeDifferentTonight => 'Tonight feels a little different';

  @override
  String get homeOtherWays => 'Try another approach';

  @override
  String get homeBrowseTitle => 'Browse all sounds';

  @override
  String get homeBrowseSubtitle =>
      'Search, filter, favorite, or keep online audio on this device';

  @override
  String get homeCandidatesTitle => 'Preview candidate sounds';

  @override
  String homeCandidatesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count public candidates; internet required and listening review is pending',
      one:
          '1 public candidate; internet required and listening review is pending',
    );
    return '$_temp0';
  }

  @override
  String get candidateLibraryTitle => 'Candidate sounds\nfor listening review';

  @override
  String get candidateLibrarySubtitle =>
      'Search, favorite, or download a sound to listen later.';

  @override
  String get homeVoiceTitle => 'Listen to a calming voice';

  @override
  String get homeVoiceSubtitle =>
      'Gentle readings and spoken content in your preferred language';

  @override
  String get voiceLibraryTitle => 'Calming voices';

  @override
  String get voiceLibrarySubtitle =>
      'Choose a voice and length that appeal to you.';

  @override
  String get homeKnowledgeTitle => 'Listen to something quietly informative';

  @override
  String get homeKnowledgeSubtitle =>
      'Courses, reference readings, and technical topics';

  @override
  String get knowledgeLibraryTitle => 'Quiet knowledge';

  @override
  String get knowledgeLibrarySubtitle =>
      'Choose a voice, subject, and length you prefer.';

  @override
  String get homeNightAwakeTitle => 'When you wake at night';

  @override
  String get homeNightAwakeSubtitle =>
      'Start a familiar sound without checking the time';

  @override
  String get homeMorningTitle => 'After waking';

  @override
  String get homeMorningSubtitle =>
      'Notice how restored you feel, or explore last night\'s dream';

  @override
  String get homeHistoryTitle => 'Recent nights';

  @override
  String get homeHistorySubtitle =>
      'Review local records or connect watch and system sleep data';

  @override
  String get homeFooter => 'Come back whenever it helps.';

  @override
  String get aboutTagline => 'A quieter way to settle.';

  @override
  String get aboutPrototypeNotice =>
      'Stillow is currently an experience prototype, not a tool for diagnosing or treating sleep disorders. If you often wake gasping, have observed breathing pauses, or daytime sleepiness affects driving safety, seek professional advice.';

  @override
  String get interfaceLanguageTitle => 'Interface language';

  @override
  String get interfaceLanguageDescription =>
      'Follow the system by default, or choose a language here.';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get audioLanguageTitle => 'Spoken-audio language';

  @override
  String get audioLanguageDescription =>
      'Sounds without speech stay available; spoken items follow this preference.';

  @override
  String get audioLanguageAutomatic => 'Match interface';

  @override
  String get audioLanguageChinese => 'Chinese speech';

  @override
  String get audioLanguageEnglish => 'English speech';

  @override
  String get audioLanguageAny => 'All languages';

  @override
  String get contentRegionTitle => 'Content region';

  @override
  String get contentRegionDescription =>
      'Automatic mode follows the device region. You can override it at any time.';

  @override
  String get contentRegionAutomaticChina => 'Auto · China';

  @override
  String get contentRegionAutomaticInternational => 'Auto · International';

  @override
  String get contentRegionChina => 'China sources';

  @override
  String get contentRegionInternational => 'International sources';

  @override
  String get adjustPreferences => 'Adjust support preferences';

  @override
  String get dataAndPrivacy => 'Data and privacy';

  @override
  String get viewLatestVersion => 'View latest release';

  @override
  String get releaseNotes => 'Versions and release notes';

  @override
  String get githubOpenFailed =>
      'GitHub could not be opened just now. Please try again later.';

  @override
  String get recommendationTryTonight => 'Try tonight';

  @override
  String get supportDifferentPathTitle => 'Try a very different kind of sound';

  @override
  String get supportProfessionalTitle => 'Sound may not be the whole answer';

  @override
  String get supportDifferentPathBody =>
      'Recent sounds have not helped much. Try a different feel across voice, music, and nature audio.';

  @override
  String get supportProfessionalBody =>
      'If several attempts have not helped, you can review when it may be worth speaking with a professional.';

  @override
  String get supportLearnMore => 'Learn more';

  @override
  String get feedbackSaveFailed =>
      'That feedback was not saved. You can try again.';

  @override
  String get feedbackIntro => 'When you have a moment';

  @override
  String get feedbackBedtimeQuestion => 'How did the last sound feel?';

  @override
  String get feedbackNightQuestion => 'How did the sound feel after waking?';

  @override
  String get feedbackComfortable => 'Comforting';

  @override
  String get feedbackNightComfortable => 'I settled more easily';

  @override
  String get feedbackNoDifference => 'No clear difference';

  @override
  String get feedbackNotForMe => 'Not a good fit';

  @override
  String get feedbackNightNotForMe => 'It made me more alert';

  @override
  String get tonightStateTitle => 'What feels closest\ntonight?';

  @override
  String get tonightStateSubtitle =>
      'Choose the first answer that feels close.';

  @override
  String get stateBusyMind => 'My thoughts are busy';

  @override
  String get stateNotSleepy => 'My mind is quiet; I am just not sleepy';

  @override
  String get stateSleepPressure => 'I feel pressure to sleep';

  @override
  String get stateTenseBody => 'My body has not loosened up';

  @override
  String get stateNoisyRoom => 'The room feels noisy';

  @override
  String get stateNightAwake => 'I woke during the night';

  @override
  String get stateUnsure => 'I am not sure';

  @override
  String get tonightStateSkip => 'Skip and use the familiar approach';

  @override
  String get libraryDefaultTitle => 'Find another\ncomfortable sound';

  @override
  String get libraryDefaultSubtitle => 'Choose what suits this moment.';

  @override
  String get downloadComplete => 'This sound is now available on this device.';

  @override
  String get downloadFailed =>
      'The download did not finish. Try again when the connection is steady.';

  @override
  String get downloadCancelled => 'The download was stopped.';

  @override
  String get downloadQuotaExceeded =>
      'Offline sounds are using quite a bit of space on this device. Remove some before downloading more.';

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get removeDownloadTitle => 'Remove this offline sound?';

  @override
  String get removeDownloadBody =>
      'Only the downloaded file will be removed. The favorite stays, and you can stream or download it again.';

  @override
  String get removeOfflineFile => 'Remove offline file';

  @override
  String get librarySearchHint => 'Search sounds, creators, or topics';

  @override
  String get libraryCheckingOffline =>
      'Checking which sounds are on this device…';

  @override
  String libraryAvailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sounds available',
      one: '1 sound available',
    );
    return '$_temp0';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String get filterAmbient => 'Ambient';

  @override
  String get filterMusic => 'Music';

  @override
  String get filterVoice => 'Voice';

  @override
  String get filterCourses => 'Knowledge';

  @override
  String get filterOffline => 'Offline';

  @override
  String get candidateAwaitingReview => 'Awaiting review';

  @override
  String get availableOffline => 'Available offline';

  @override
  String get online => 'Online';

  @override
  String get unfavorite => 'Remove favorite';

  @override
  String get favorite => 'Favorite';

  @override
  String get bundledOffline => 'Included for offline use';

  @override
  String get manageOfflineFile => 'Manage offline file';

  @override
  String get downloadToDevice => 'Download to device';

  @override
  String get spokenChinese => 'Chinese';

  @override
  String get spokenEnglish => 'English';

  @override
  String get spokenCantonese => 'Cantonese';

  @override
  String get spokenTraditionalChinese => 'Traditional Chinese';

  @override
  String get noSpokenLanguage => 'No speech';

  @override
  String get emptyFavorites =>
      'No favorites yet. Tap the heart when a sound feels comfortable.';

  @override
  String get emptyLibrary =>
      'No matching sounds here. Try another word or filter.';

  @override
  String get playerCreditsTitle => 'About this sound';

  @override
  String get viewSource => 'View source';

  @override
  String get viewLicense => 'View license';

  @override
  String get sleepTimerTitle => 'Let the sound fade away';

  @override
  String get sleepTimerBody =>
      'The final 30 seconds fade gently. You can also leave the timer off.';

  @override
  String minutesLabel(int minutes) {
    return '$minutes min';
  }

  @override
  String get noTimer => 'No timer';

  @override
  String get playerCompleteTitle => 'The sound has faded away';

  @override
  String get playerNightCompleteBody =>
      'If sleepiness remains, let the screen go dark. If you feel more alert, sit somewhere dim and quiet, then return to bed when sleepiness comes back.';

  @override
  String get playerCompleteBody =>
      'The sound ends here. Let the screen go dark and keep resting.';

  @override
  String get playerNightBody =>
      'Keep the volume low and let the sound sit in the background.';

  @override
  String useOfflineFallback(String title) {
    return 'Use offline “$title”';
  }

  @override
  String get playingCandidate => 'Playing an ad-free candidate';

  @override
  String get playingAudio => 'Playing ad-free audio';

  @override
  String get tapToPreview => 'Tap to preview';

  @override
  String get tapToPlay => 'Tap to play';

  @override
  String get setFadeTimer => 'Set fade timer';

  @override
  String get fadeTimerSet => 'Fade timer set';

  @override
  String get quietFinish => 'End quietly';

  @override
  String get stopHere => 'Stop here';

  @override
  String get playbackLoadFailed =>
      'This sound could not be loaded. Try another one.';

  @override
  String get playbackInterrupted => 'Loading was interrupted. Try again later.';

  @override
  String get playbackUnavailable =>
      'This sound is unavailable just now. Try another one.';

  @override
  String get playbackStoppedRetry =>
      'Playback stopped. Try again or choose another sound.';

  @override
  String get playbackStopped => 'Playback stopped. Try another sound.';

  @override
  String get nightPresetLibraryTitle => 'Default sound\nfor waking at night';

  @override
  String get nightPresetLibrarySubtitle =>
      'Choose a familiar sound. You can change it later.';

  @override
  String get nightStartFailed => 'This sound could not start. Try another one.';

  @override
  String get nightAwakeHeading => 'You are awake right now.';

  @override
  String get nightAwakeBody => 'Let your body and attention settle gradually.';

  @override
  String nightReady(String title) {
    return 'Ready to play · $title';
  }

  @override
  String get nightChangePreset => 'Change night-waking preset';

  @override
  String get nightStart => 'Help me settle';

  @override
  String get nightPhysicalNeeds =>
      'If you have pain, breathing discomfort, or need the bathroom, take care of your body first.';

  @override
  String get morningRestedSummary => 'You seem fairly restored today.';

  @override
  String get morningOrdinarySummary =>
      'Your sense of recovery feels fairly ordinary today.';

  @override
  String get morningTiredSummary =>
      'Last night may not have felt very restful.';

  @override
  String get morningTitle => 'How do you feel\nafter waking?';

  @override
  String get morningSubtitle =>
      'Choose from how you feel right now. There is no right answer.';

  @override
  String get feelingRested => 'Quite refreshed';

  @override
  String get feelingOrdinary => 'About average';

  @override
  String get feelingTired => 'Still a little tired';

  @override
  String get morningSubjectiveOnly =>
      'This is how you feel right now, not a sleep score.';

  @override
  String get morningSaving => 'Saving gently on this device…';

  @override
  String get morningSaved =>
      'This is a personal feeling, not a sleep score. It stays on this device for up to 30 days.';

  @override
  String get morningDreamTitle => 'Remember a dream from last night?';

  @override
  String get morningDreamBody =>
      'Write down a few images for a light, just-for-fun interpretation.';

  @override
  String get morningDreamAction => 'Explore my dream';

  @override
  String get dreamTitle => 'What happened\nin your dream?';

  @override
  String get dreamSubtitle =>
      'Write a few images, people, or feelings you remember.';

  @override
  String get dreamHint =>
      'For example: I was in an unfamiliar house, and rain kept falling outside…';

  @override
  String get dreamAction => 'Explore this dream';

  @override
  String get dreamPrivacy =>
      'Text is interpreted only on this page and is not saved when you leave.';

  @override
  String get dreamReadingTitle => 'One playful way to read it';

  @override
  String get dreamDisclaimer =>
      'For entertainment only. Dreams have no single answer; this does not predict the future or provide a psychological diagnosis.';

  @override
  String get privacyClearTitle => 'Clear all sleep records?';

  @override
  String get privacyClearBody =>
      'Sound sessions, morning feelings, and synced health records will be removed from this device. Favorites, preferences, and My sounds remain.';

  @override
  String get clearAll => 'Clear all';

  @override
  String get historyCleared =>
      'Sleep records on this device have been cleared.';

  @override
  String get privacyTitle => 'Data and privacy';

  @override
  String get privacyIntro =>
      'Stillow has no account, website, server, or cloud sync. The data below stays on this device and is excluded from system cloud backups.';

  @override
  String get privacyLocalTitle => 'Minimal local history';

  @override
  String get privacyLocalBody =>
      'Up to 30 days of sound sessions, listening time, bedtime or night-waking context, and morning feelings you choose. It is not restored after uninstalling or changing devices.';

  @override
  String get privacyUserSoundsTitle => 'Sounds you add';

  @override
  String get privacyUserSoundsBody =>
      'Stillow stores the path to the file you chose and does not copy the audio into the app. Nothing is uploaded. Removing a sound from the list does not delete the original file on your phone. Any older private copies are still removed when you delete the item or uninstall.';

  @override
  String get privacyHealthTitle => 'Health data connects only when you choose';

  @override
  String get privacyHealthBody =>
      'Only sleep periods and stages are stored. Stillow does not retain health UUIDs, device names, heart rate, or HRV; it does not write health data or sync in the background. Disconnecting clears the app\'s health cache.';

  @override
  String get privacyDreamTitle => 'Dream text is not saved';

  @override
  String get privacyDreamBody =>
      'Dream interpretation happens only on its current page. Your text is not written to local history after you leave.';

  @override
  String get privacyTrendTitle => 'Trends are not a diagnosis';

  @override
  String get privacyTrendBody =>
      'Device records and morning feelings are for gentle reflection. They do not create a medical sleep score or diagnose or treat a condition.';

  @override
  String get clearSleepHistory => 'Clear all sleep records';

  @override
  String get reviewProfessionalTitle => 'Consider talking with a professional';

  @override
  String get reviewObserveTitle => 'Keep observing for a while';

  @override
  String get reviewProfessionalBody =>
      'Your answers include signs that the difficulty is persistent, frequent, or affecting daytime life. A sleep clinic, primary-care clinician, or professional familiar with sleep may be more useful than continuing to switch sounds.';

  @override
  String get reviewObserveBody =>
      'These answers are not enough to suggest chronic insomnia. Keep noticing your experience; you can speak with a professional if the difficulty grows or you would simply like help making sense of it.';

  @override
  String get reviewClinicalContext =>
      'A clinical assessment often considers whether difficulty happens about three nights a week or more, lasts around three months or longer, affects daytime life, and occurs despite enough time and a suitable setting for sleep. This page does not diagnose or calculate a score.';

  @override
  String get reviewSleepOpportunityNote =>
      'You also noted that there often has not been enough time for sleep. Addressing that practical condition may help. If that is difficult or daytime life already feels hard, professional support is also reasonable.';

  @override
  String get reviewBreathingSafety =>
      'Seek medical advice promptly if you often wake choking or gasping, someone notices breathing pauses, or sleepiness affects driving safety.';

  @override
  String get reviewTreatmentNote =>
      'A professional assessment may discuss CBT-I, other sleep conditions, and medication when appropriate. Medication is not an automatic recommendation from this app.';

  @override
  String get understood => 'Got it';

  @override
  String get reviewDismiss => 'Skip review';

  @override
  String get reviewTitle => 'A gentle check-in';

  @override
  String get reviewIntro =>
      'This is not a test and it will not label you. Answer only what feels comfortable; choices stay on this page and are not saved.';

  @override
  String get reviewDurationQuestion =>
      'About how long has falling asleep or returning to sleep been difficult?';

  @override
  String get reviewUnderMonth => 'Less than 1 month';

  @override
  String get reviewOneToThreeMonths => '1–3 months';

  @override
  String get reviewThreeMonths => '3 months or longer';

  @override
  String get reviewUnsure => 'Not sure';

  @override
  String get reviewFrequencyQuestion =>
      'In the past week, about how many nights did this happen?';

  @override
  String get reviewLessThanWeekly => 'Less than once a week';

  @override
  String get reviewOneTwoNights => '1–2 nights a week';

  @override
  String get reviewThreeNights => '3 or more nights a week';

  @override
  String get reviewFrequencyUnsure => 'Hard to say';

  @override
  String get reviewDaytimeQuestion =>
      'How does it affect daytime energy, attention, or mood?';

  @override
  String get reviewImpactLittle => 'Hardly at all';

  @override
  String get reviewImpactNoticeable => 'I notice some effect';

  @override
  String get reviewImpactClear => 'A clear effect or safety concern';

  @override
  String get reviewOpportunityQuestion =>
      'Do you usually have enough time and a reasonably suitable place to sleep?';

  @override
  String get reviewOpportunityEnough => 'Most of the time';

  @override
  String get reviewOpportunityVaries => 'Sometimes';

  @override
  String get reviewOpportunityNotEnough => 'Usually not';

  @override
  String get reviewShowResult => 'View guidance';

  @override
  String get reviewSkip => 'Skip for now';

  @override
  String get healthPermissionTitle => 'Read recent sleep records only';

  @override
  String get healthPermissionBody =>
      'The system will ask whether Stillow may read sleep periods and stages. Stillow does not read heart rate or HRV, write health data, or sync in the background.';

  @override
  String get healthNotNow => 'Not now';

  @override
  String get healthInstallReturn =>
      'After installing or updating, return here to connect.';

  @override
  String get healthDisconnectTitle => 'Disconnect health data?';

  @override
  String get healthDisconnectIosBody =>
      'Stillow\'s saved health records will be cleared. Manage Apple Health read access separately in the Health app.';

  @override
  String get healthDisconnectAndroidBody =>
      'Stillow\'s Health Connect permission will be revoked and its saved health records cleared.';

  @override
  String get healthDisconnectAction => 'Disconnect and clear';

  @override
  String get healthDisconnectedIos =>
      'Health records in Stillow were cleared. Manage system access in Apple Health.';

  @override
  String get healthDisconnectedAndroid =>
      'Health Connect was disconnected and the local cache was cleared.';

  @override
  String get historyRemoveNightTitle => 'Remove this night\'s local record?';

  @override
  String get historyRemoveNightBody =>
      'Only Stillow\'s sound-session record and morning feeling will be removed. System health data is unchanged.';

  @override
  String get remove => 'Remove';

  @override
  String get historyClearTitle => 'Clear all records in Stillow?';

  @override
  String get historyClearBody =>
      'Sound sessions, morning feelings, and synced health records will be removed from this device. Favorites and preferences remain.';

  @override
  String get historyTitle => 'Recent nights';

  @override
  String get historyIntro =>
      'A simple review, without a sleep score. Records are kept for up to 30 days.';

  @override
  String get localHistoryTitle => 'Stillow local records';

  @override
  String get historyEmpty =>
      'No local records yet. Play a sound or choose a morning feeling, and this page will gradually fill in.';

  @override
  String healthLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get healthOptional =>
      'Connect only if you choose. Stillow does not ask during first launch.';

  @override
  String get healthInstallRequired =>
      'Health Connect needs to be installed or updated.';

  @override
  String get healthUnavailable =>
      'System sleep data is not available on this device.';

  @override
  String get healthCardTitle => 'Watch and system sleep records';

  @override
  String get healthConnectSync => 'Connect and sync';

  @override
  String get healthUpdate => 'Update recent records';

  @override
  String get healthInstall => 'Install or update Health Connect';

  @override
  String get healthDisconnectCache => 'Disconnect and clear health cache';

  @override
  String get healthTrendTitle => 'Recorded sleep-window trend';

  @override
  String get healthTrendBody =>
      'The line shows the recorded start-to-end window, not a sleep-quality score.';

  @override
  String get healthDeviceRecords => 'Device records';

  @override
  String get healthStagesAvailable => 'The device also provided sleep stages';

  @override
  String get healthTimelineSemantics =>
      'Sleep-stage timeline supplied by the device, for review only and not a sleep score';

  @override
  String get healthTimelineLegend =>
      'Light · Deep · REM · Awake (as recorded by the device)';

  @override
  String historyMorningFeeling(String feeling) {
    return 'On waking: $feeling';
  }

  @override
  String get historyNightSession => 'Night-waking support';

  @override
  String get historyBedtimeSession => 'Bedtime support';

  @override
  String historySessionLine(String context, String duration) {
    return '$context · $duration';
  }

  @override
  String get historyRemoveNightTooltip => 'Remove this night\'s local record';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours hr';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String get healthSyncUnavailable =>
      'This device cannot read system sleep records just now.';

  @override
  String get healthSyncPermissionDeclined =>
      'Read access was not granted. You can start here again whenever you want to connect.';

  @override
  String get healthSyncNoData =>
      'No sleep records were found in the past 30 days, or the system may not have made them available.';

  @override
  String get healthSyncSuccess =>
      'Recent records on this device are up to date.';

  @override
  String get healthSyncFailedUnlocked =>
      'Sync did not finish. Try again while the device is unlocked.';

  @override
  String get healthSyncFailed => 'Sync did not finish. Try again later.';

  @override
  String get userSoundsTitle => 'My sounds';

  @override
  String get cancel => 'Cancel';

  @override
  String get userSoundsSubtitle =>
      'What is in the list plays in order. Remove a file from the list when you no longer want it.';

  @override
  String userSoundsUsage(int count, String used) {
    return '$count/20 sounds · $used MB used';
  }

  @override
  String get userSoundsHomeTitle => 'My sounds';

  @override
  String get userSoundsHomeSubtitle =>
      'Files in the list play in order. Remove one when you no longer want it.';

  @override
  String get userSoundsEmptyTitle => 'No sounds here yet';

  @override
  String get userSoundsEmptyBody =>
      'Add one or more familiar tracks, lessons, or readings. Stillow stores the paths and plays the list. Remove a file from the list when you no longer want it.';

  @override
  String get userSoundsAdd => 'Add a sound';

  @override
  String get userSoundsPlayList => 'Play the list';

  @override
  String get userSoundsPrevious => 'Previous';

  @override
  String get userSoundsNext => 'Next';

  @override
  String userSoundsPlaylistPosition(int current, int total) {
    return '$current / $total';
  }

  @override
  String get userSoundsImportTitle => 'Add audio from this device';

  @override
  String get userSoundsImportNotice =>
      'Choose MP3 or M4A files you have the right to use. You can pick several at once. Stillow stores the paths, keeps them in a playable list, does not copy them into the app, and never uploads them. Remove a file from the list when you no longer want it; the original file stays on your phone. You can keep up to 20 sounds.';

  @override
  String get userSoundsChooseFile => 'Choose file';

  @override
  String get userSoundsImporting => 'Adding…';

  @override
  String get userSoundsCancelImport => 'Cancel adding';

  @override
  String get userSoundsImportCancelled => 'Adding the sound was cancelled.';

  @override
  String get userSoundsUnsupported =>
      'Only MP3 and M4A files are supported for now.';

  @override
  String get userSoundsEmptyFile =>
      'This file does not contain playable audio.';

  @override
  String get userSoundsLibraryFull => 'You can keep up to 20 sounds.';

  @override
  String get userSoundsSourceUnavailable =>
      'Stillow could not read that file. Please choose it again.';

  @override
  String get userSoundsImportInProgress =>
      'Another sound is already being added.';

  @override
  String get userSoundsWriteFailed =>
      'The sound was not saved. Check device space and try again.';

  @override
  String get userSoundsEdit => 'Sound settings';

  @override
  String get userSoundsRename => 'Name';

  @override
  String get userSoundsLoop => 'Loop playback';

  @override
  String get userSoundsLoopBody => 'Useful for music or ambient sound.';

  @override
  String get userSoundsAttenuate => 'Softer after each loop';

  @override
  String get userSoundsAttenuateBody =>
      'The volume gradually lowers as the sound repeats.';

  @override
  String get userSoundsDefaultTimer => 'Default fade timer';

  @override
  String get userSoundsNoDefaultTimer => 'Do not stop automatically';

  @override
  String get userSoundsSave => 'Save settings';

  @override
  String get userSoundsDelete => 'Remove from list';

  @override
  String get userSoundsDeleteTitle => 'Remove from the play list?';

  @override
  String get userSoundsDeleteBody =>
      'It will no longer play. The original file on your phone stays where it is.';

  @override
  String get userSoundsRemoveFromList => 'Remove from list';

  @override
  String get userSoundLocalBadge => 'My sounds · stored only on this device';

  @override
  String get userSoundLocalSubtitle => 'Audio from this device';

  @override
  String get userSoundLocalShortLabel => 'My sounds';

  @override
  String get userSoundLocalCreator => 'Local file';

  @override
  String get userSoundsSaved => 'Settings saved.';

  @override
  String get userSoundsOperationFailed =>
      'That did not finish. Please try again later.';

  @override
  String get nightPresetPersonalTitle => 'My sounds';

  @override
  String get nightPresetBuiltInTitle => 'Stillow sounds';
}
