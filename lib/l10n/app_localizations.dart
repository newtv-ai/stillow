import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Stillow'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @finish.
  ///
  /// In zh, this message translates to:
  /// **'结束'**
  String get finish;

  /// No description provided for @continueLabel.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get continueLabel;

  /// No description provided for @keepForNow.
  ///
  /// In zh, this message translates to:
  /// **'先留着'**
  String get keepForNow;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clear;

  /// No description provided for @play.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @onboardingSkip.
  ///
  /// In zh, this message translates to:
  /// **'先随便听听'**
  String get onboardingSkip;

  /// No description provided for @onboardingKeep.
  ///
  /// In zh, this message translates to:
  /// **'保留现在'**
  String get onboardingKeep;

  /// No description provided for @onboardingTryTonight.
  ///
  /// In zh, this message translates to:
  /// **'今晚先试试'**
  String get onboardingTryTonight;

  /// No description provided for @onboardingNeedTitle.
  ///
  /// In zh, this message translates to:
  /// **'今晚，你更希望得到哪种陪伴？'**
  String get onboardingNeedTitle;

  /// No description provided for @onboardingNeedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'凭第一感觉，选最接近此刻的一项。'**
  String get onboardingNeedSubtitle;

  /// No description provided for @needQuietMind.
  ///
  /// In zh, this message translates to:
  /// **'想法停不下来'**
  String get needQuietMind;

  /// No description provided for @needNotSleepy.
  ///
  /// In zh, this message translates to:
  /// **'脑袋没想什么，但还不困'**
  String get needNotSleepy;

  /// No description provided for @needSleepPressure.
  ///
  /// In zh, this message translates to:
  /// **'越想赶快睡，反而越清醒'**
  String get needSleepPressure;

  /// No description provided for @needRelaxBody.
  ///
  /// In zh, this message translates to:
  /// **'让身体松下来'**
  String get needRelaxBody;

  /// No description provided for @needMaskNoise.
  ///
  /// In zh, this message translates to:
  /// **'把周围动静放远一点'**
  String get needMaskNoise;

  /// No description provided for @needNightAwake.
  ///
  /// In zh, this message translates to:
  /// **'夜里醒来后，不容易再睡'**
  String get needNightAwake;

  /// No description provided for @needGentleCompany.
  ///
  /// In zh, this message translates to:
  /// **'说不上来，只想有人陪一会儿'**
  String get needGentleCompany;

  /// No description provided for @onboardingSoundTitle.
  ///
  /// In zh, this message translates to:
  /// **'什么声音会让你舒服一些？'**
  String get onboardingSoundTitle;

  /// No description provided for @onboardingSoundSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'先选此刻更喜欢的声音，之后随时可以更换。'**
  String get onboardingSoundSubtitle;

  /// No description provided for @soundSoftVoice.
  ///
  /// In zh, this message translates to:
  /// **'轻柔的人声或中文朗读'**
  String get soundSoftVoice;

  /// No description provided for @soundFamiliarMusic.
  ///
  /// In zh, this message translates to:
  /// **'熟悉、平缓的音乐'**
  String get soundFamiliarMusic;

  /// No description provided for @soundNature.
  ///
  /// In zh, this message translates to:
  /// **'雨声、风声等环境声'**
  String get soundNature;

  /// No description provided for @soundMinimal.
  ///
  /// In zh, this message translates to:
  /// **'更喜欢安静，只要少量提示'**
  String get soundMinimal;

  /// No description provided for @onboardingGuidanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'你喜欢怎样的陪伴？'**
  String get onboardingGuidanceTitle;

  /// No description provided for @onboardingGuidanceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'选择更喜欢的陪伴程度。'**
  String get onboardingGuidanceSubtitle;

  /// No description provided for @guidanceStepByStep.
  ///
  /// In zh, this message translates to:
  /// **'带着我一步步放松'**
  String get guidanceStepByStep;

  /// No description provided for @guidanceOccasional.
  ///
  /// In zh, this message translates to:
  /// **'偶尔提醒一下就好'**
  String get guidanceOccasional;

  /// No description provided for @guidanceAmbientOnly.
  ///
  /// In zh, this message translates to:
  /// **'只听声音，保持安静'**
  String get guidanceAmbientOnly;

  /// No description provided for @homeSettingsTooltip.
  ///
  /// In zh, this message translates to:
  /// **'设置与关于 Stillow'**
  String get homeSettingsTooltip;

  /// No description provided for @homeGreeting.
  ///
  /// In zh, this message translates to:
  /// **'今晚，\n慢一点。'**
  String get homeGreeting;

  /// No description provided for @homePrompt.
  ///
  /// In zh, this message translates to:
  /// **'选一段此刻喜欢的声音。'**
  String get homePrompt;

  /// No description provided for @homeDifferentTonight.
  ///
  /// In zh, this message translates to:
  /// **'今晚感觉有点不同'**
  String get homeDifferentTonight;

  /// No description provided for @homeOtherWays.
  ///
  /// In zh, this message translates to:
  /// **'想换一种方式'**
  String get homeOtherWays;

  /// No description provided for @homeBrowseTitle.
  ///
  /// In zh, this message translates to:
  /// **'看看其他陪伴'**
  String get homeBrowseTitle;

  /// No description provided for @homeBrowseSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索、分类、收藏，或把在线声音留到设备里'**
  String get homeBrowseSubtitle;

  /// No description provided for @homeCandidatesTitle.
  ///
  /// In zh, this message translates to:
  /// **'试听候选声音'**
  String get homeCandidatesTitle;

  /// No description provided for @homeCandidatesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{count} 段公开候选，需要联网，听感仍在筛选中'**
  String homeCandidatesSubtitle(int count);

  /// No description provided for @candidateLibraryTitle.
  ///
  /// In zh, this message translates to:
  /// **'候选声音\n试听列表'**
  String get candidateLibraryTitle;

  /// No description provided for @candidateLibrarySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'可以搜索、收藏，或下载到设备后慢慢听。'**
  String get candidateLibrarySubtitle;

  /// No description provided for @homeVoiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'听一段舒缓人声'**
  String get homeVoiceTitle;

  /// No description provided for @homeVoiceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'按语言偏好选择舒缓朗读与轻声内容'**
  String get homeVoiceSubtitle;

  /// No description provided for @voiceLibraryTitle.
  ///
  /// In zh, this message translates to:
  /// **'舒缓人声'**
  String get voiceLibraryTitle;

  /// No description provided for @voiceLibrarySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'选择更喜欢的音色和篇幅。'**
  String get voiceLibrarySubtitle;

  /// No description provided for @homeKnowledgeTitle.
  ///
  /// In zh, this message translates to:
  /// **'听一段平缓的知识'**
  String get homeKnowledgeTitle;

  /// No description provided for @homeKnowledgeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'课程、百科与技术朗读，按声音和篇幅挑一段'**
  String get homeKnowledgeSubtitle;

  /// No description provided for @knowledgeLibraryTitle.
  ///
  /// In zh, this message translates to:
  /// **'知识陪伴'**
  String get knowledgeLibraryTitle;

  /// No description provided for @knowledgeLibrarySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'选择更喜欢的声音、主题和篇幅。'**
  String get knowledgeLibrarySubtitle;

  /// No description provided for @homeNightAwakeTitle.
  ///
  /// In zh, this message translates to:
  /// **'夜里醒来时'**
  String get homeNightAwakeTitle;

  /// No description provided for @homeNightAwakeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'不看时间，一键开始预设陪伴'**
  String get homeNightAwakeSubtitle;

  /// No description provided for @homeMorningTitle.
  ///
  /// In zh, this message translates to:
  /// **'醒来以后'**
  String get homeMorningTitle;

  /// No description provided for @homeMorningSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'看看此刻的恢复感，或者轻松聊聊昨晚的梦'**
  String get homeMorningSubtitle;

  /// No description provided for @homeHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'最近的夜晚'**
  String get homeHistoryTitle;

  /// No description provided for @homeHistorySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'回顾本地记录，或主动连接手表与系统睡眠数据'**
  String get homeHistorySubtitle;

  /// No description provided for @homeFooter.
  ///
  /// In zh, this message translates to:
  /// **'想用时再来。'**
  String get homeFooter;

  /// No description provided for @aboutTagline.
  ///
  /// In zh, this message translates to:
  /// **'陪你慢慢安静。'**
  String get aboutTagline;

  /// No description provided for @aboutPrototypeNotice.
  ///
  /// In zh, this message translates to:
  /// **'Stillow 当前是体验原型，不用于诊断或治疗睡眠疾病。如果经常憋醒、呼吸暂停，或白天困倦已经影响驾驶安全，更适合先找专业人士确认。'**
  String get aboutPrototypeNotice;

  /// No description provided for @interfaceLanguageTitle.
  ///
  /// In zh, this message translates to:
  /// **'界面语言'**
  String get interfaceLanguageTitle;

  /// No description provided for @interfaceLanguageDescription.
  ///
  /// In zh, this message translates to:
  /// **'默认跟随系统，也可以在这里单独选择。'**
  String get interfaceLanguageDescription;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @audioLanguageTitle.
  ///
  /// In zh, this message translates to:
  /// **'人声音频语言'**
  String get audioLanguageTitle;

  /// No description provided for @audioLanguageDescription.
  ///
  /// In zh, this message translates to:
  /// **'无人声音频始终可用；人声内容按这里的偏好筛选。'**
  String get audioLanguageDescription;

  /// No description provided for @audioLanguageAutomatic.
  ///
  /// In zh, this message translates to:
  /// **'跟随界面'**
  String get audioLanguageAutomatic;

  /// No description provided for @audioLanguageChinese.
  ///
  /// In zh, this message translates to:
  /// **'中文人声'**
  String get audioLanguageChinese;

  /// No description provided for @audioLanguageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'英文人声'**
  String get audioLanguageEnglish;

  /// No description provided for @audioLanguageAny.
  ///
  /// In zh, this message translates to:
  /// **'全部语言'**
  String get audioLanguageAny;

  /// No description provided for @contentRegionTitle.
  ///
  /// In zh, this message translates to:
  /// **'素材区域'**
  String get contentRegionTitle;

  /// No description provided for @contentRegionDescription.
  ///
  /// In zh, this message translates to:
  /// **'自动模式会跟随设备地区；也可以手动切换，随时改回来。'**
  String get contentRegionDescription;

  /// No description provided for @contentRegionAutomaticChina.
  ///
  /// In zh, this message translates to:
  /// **'自动 · 国内'**
  String get contentRegionAutomaticChina;

  /// No description provided for @contentRegionAutomaticInternational.
  ///
  /// In zh, this message translates to:
  /// **'自动 · 国际'**
  String get contentRegionAutomaticInternational;

  /// No description provided for @contentRegionChina.
  ///
  /// In zh, this message translates to:
  /// **'国内素材'**
  String get contentRegionChina;

  /// No description provided for @contentRegionInternational.
  ///
  /// In zh, this message translates to:
  /// **'国际素材'**
  String get contentRegionInternational;

  /// No description provided for @adjustPreferences.
  ///
  /// In zh, this message translates to:
  /// **'调整陪伴偏好'**
  String get adjustPreferences;

  /// No description provided for @dataAndPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'数据与隐私'**
  String get dataAndPrivacy;

  /// No description provided for @viewLatestVersion.
  ///
  /// In zh, this message translates to:
  /// **'查看最新版本'**
  String get viewLatestVersion;

  /// No description provided for @releaseNotes.
  ///
  /// In zh, this message translates to:
  /// **'版本与更新说明'**
  String get releaseNotes;

  /// No description provided for @githubOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂时没能打开 GitHub，可以稍后再试。'**
  String get githubOpenFailed;

  /// No description provided for @recommendationTryTonight.
  ///
  /// In zh, this message translates to:
  /// **'今晚先试试'**
  String get recommendationTryTonight;

  /// No description provided for @supportDifferentPathTitle.
  ///
  /// In zh, this message translates to:
  /// **'换条完全不同的路试试'**
  String get supportDifferentPathTitle;

  /// No description provided for @supportProfessionalTitle.
  ///
  /// In zh, this message translates to:
  /// **'声音可能不是全部答案'**
  String get supportProfessionalTitle;

  /// No description provided for @supportDifferentPathBody.
  ///
  /// In zh, this message translates to:
  /// **'最近试过的声音帮助有限，可以在人声、音乐和自然声之间换一种感受。'**
  String get supportDifferentPathBody;

  /// No description provided for @supportProfessionalBody.
  ///
  /// In zh, this message translates to:
  /// **'如果已经多次尝试仍没帮助，可以选择了解什么时候值得找专业人士聊聊。'**
  String get supportProfessionalBody;

  /// No description provided for @supportLearnMore.
  ///
  /// In zh, this message translates to:
  /// **'我想了解一下'**
  String get supportLearnMore;

  /// No description provided for @feedbackSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'这次反馈没能保存，可以再试一次。'**
  String get feedbackSaveFailed;

  /// No description provided for @feedbackIntro.
  ///
  /// In zh, this message translates to:
  /// **'有空的时候，告诉我们'**
  String get feedbackIntro;

  /// No description provided for @feedbackBedtimeQuestion.
  ///
  /// In zh, this message translates to:
  /// **'上次那段陪伴感觉怎么样？'**
  String get feedbackBedtimeQuestion;

  /// No description provided for @feedbackNightQuestion.
  ///
  /// In zh, this message translates to:
  /// **'夜醒后的那段陪伴呢？'**
  String get feedbackNightQuestion;

  /// No description provided for @feedbackComfortable.
  ///
  /// In zh, this message translates to:
  /// **'挺舒服的'**
  String get feedbackComfortable;

  /// No description provided for @feedbackNightComfortable.
  ///
  /// In zh, this message translates to:
  /// **'比较容易安静下来'**
  String get feedbackNightComfortable;

  /// No description provided for @feedbackNoDifference.
  ///
  /// In zh, this message translates to:
  /// **'没有明显区别'**
  String get feedbackNoDifference;

  /// No description provided for @feedbackNotForMe.
  ///
  /// In zh, this message translates to:
  /// **'不太适合'**
  String get feedbackNotForMe;

  /// No description provided for @feedbackNightNotForMe.
  ///
  /// In zh, this message translates to:
  /// **'反而更清醒'**
  String get feedbackNightNotForMe;

  /// No description provided for @tonightStateTitle.
  ///
  /// In zh, this message translates to:
  /// **'今晚更像是\n哪一种？'**
  String get tonightStateTitle;

  /// No description provided for @tonightStateSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'凭第一感觉，选最接近的一项。'**
  String get tonightStateSubtitle;

  /// No description provided for @stateBusyMind.
  ///
  /// In zh, this message translates to:
  /// **'想法有点多'**
  String get stateBusyMind;

  /// No description provided for @stateNotSleepy.
  ///
  /// In zh, this message translates to:
  /// **'没想什么，只是还不困'**
  String get stateNotSleepy;

  /// No description provided for @stateSleepPressure.
  ///
  /// In zh, this message translates to:
  /// **'有点着急，越想睡越清醒'**
  String get stateSleepPressure;

  /// No description provided for @stateTenseBody.
  ///
  /// In zh, this message translates to:
  /// **'身体还没松下来'**
  String get stateTenseBody;

  /// No description provided for @stateNoisyRoom.
  ///
  /// In zh, this message translates to:
  /// **'周围有点吵'**
  String get stateNoisyRoom;

  /// No description provided for @stateNightAwake.
  ///
  /// In zh, this message translates to:
  /// **'是夜里醒来后'**
  String get stateNightAwake;

  /// No description provided for @stateUnsure.
  ///
  /// In zh, this message translates to:
  /// **'说不上来'**
  String get stateUnsure;

  /// No description provided for @tonightStateSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过，继续熟悉的方式'**
  String get tonightStateSkip;

  /// No description provided for @libraryDefaultTitle.
  ///
  /// In zh, this message translates to:
  /// **'换一种\n舒服的方式'**
  String get libraryDefaultTitle;

  /// No description provided for @libraryDefaultSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'可以按此刻的感觉更换。'**
  String get libraryDefaultSubtitle;

  /// No description provided for @downloadComplete.
  ///
  /// In zh, this message translates to:
  /// **'已经留在这台设备里了。'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'这次没下载好，网络方便时再试也可以。'**
  String get downloadFailed;

  /// No description provided for @downloadCancelled.
  ///
  /// In zh, this message translates to:
  /// **'这次下载已经停下来了。'**
  String get downloadCancelled;

  /// No description provided for @downloadQuotaExceeded.
  ///
  /// In zh, this message translates to:
  /// **'设备里的离线声音已经比较多了，先移除一些再下载。'**
  String get downloadQuotaExceeded;

  /// No description provided for @cancelDownload.
  ///
  /// In zh, this message translates to:
  /// **'取消下载'**
  String get cancelDownload;

  /// No description provided for @removeDownloadTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除这份离线声音？'**
  String get removeDownloadTitle;

  /// No description provided for @removeDownloadBody.
  ///
  /// In zh, this message translates to:
  /// **'只会清理下载文件，不会取消收藏；以后仍可在线播放或重新下载。'**
  String get removeDownloadBody;

  /// No description provided for @removeOfflineFile.
  ///
  /// In zh, this message translates to:
  /// **'移除离线文件'**
  String get removeOfflineFile;

  /// No description provided for @librarySearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜声音、作者或主题'**
  String get librarySearchHint;

  /// No description provided for @libraryCheckingOffline.
  ///
  /// In zh, this message translates to:
  /// **'正在看看哪些声音已在设备里…'**
  String get libraryCheckingOffline;

  /// No description provided for @libraryAvailableCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 段可选'**
  String libraryAvailableCount(int count);

  /// No description provided for @filterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get filterAll;

  /// No description provided for @filterFavorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get filterFavorites;

  /// No description provided for @filterAmbient.
  ///
  /// In zh, this message translates to:
  /// **'环境声'**
  String get filterAmbient;

  /// No description provided for @filterMusic.
  ///
  /// In zh, this message translates to:
  /// **'音乐'**
  String get filterMusic;

  /// No description provided for @filterVoice.
  ///
  /// In zh, this message translates to:
  /// **'人声'**
  String get filterVoice;

  /// No description provided for @filterCourses.
  ///
  /// In zh, this message translates to:
  /// **'科普'**
  String get filterCourses;

  /// No description provided for @filterOffline.
  ///
  /// In zh, this message translates to:
  /// **'已离线'**
  String get filterOffline;

  /// No description provided for @candidateAwaitingReview.
  ///
  /// In zh, this message translates to:
  /// **'待试听'**
  String get candidateAwaitingReview;

  /// No description provided for @availableOffline.
  ///
  /// In zh, this message translates to:
  /// **'离线可用'**
  String get availableOffline;

  /// No description provided for @online.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get online;

  /// No description provided for @unfavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get unfavorite;

  /// No description provided for @favorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favorite;

  /// No description provided for @bundledOffline.
  ///
  /// In zh, this message translates to:
  /// **'随应用离线提供'**
  String get bundledOffline;

  /// No description provided for @manageOfflineFile.
  ///
  /// In zh, this message translates to:
  /// **'管理离线文件'**
  String get manageOfflineFile;

  /// No description provided for @downloadToDevice.
  ///
  /// In zh, this message translates to:
  /// **'下载到设备'**
  String get downloadToDevice;

  /// No description provided for @spokenChinese.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get spokenChinese;

  /// No description provided for @spokenEnglish.
  ///
  /// In zh, this message translates to:
  /// **'英文'**
  String get spokenEnglish;

  /// No description provided for @spokenCantonese.
  ///
  /// In zh, this message translates to:
  /// **'粤语'**
  String get spokenCantonese;

  /// No description provided for @spokenTraditionalChinese.
  ///
  /// In zh, this message translates to:
  /// **'繁体中文'**
  String get spokenTraditionalChinese;

  /// No description provided for @noSpokenLanguage.
  ///
  /// In zh, this message translates to:
  /// **'无人声'**
  String get noSpokenLanguage;

  /// No description provided for @emptyFavorites.
  ///
  /// In zh, this message translates to:
  /// **'还没有收藏。听到舒服的声音时，轻点小心形就好。'**
  String get emptyFavorites;

  /// No description provided for @emptyLibrary.
  ///
  /// In zh, this message translates to:
  /// **'这里暂时没有合适的结果，换个词或分类看看。'**
  String get emptyLibrary;

  /// No description provided for @playerCreditsTitle.
  ///
  /// In zh, this message translates to:
  /// **'这段声音从哪里来'**
  String get playerCreditsTitle;

  /// No description provided for @viewSource.
  ///
  /// In zh, this message translates to:
  /// **'查看来源'**
  String get viewSource;

  /// No description provided for @viewLicense.
  ///
  /// In zh, this message translates to:
  /// **'查看许可'**
  String get viewLicense;

  /// No description provided for @sleepTimerTitle.
  ///
  /// In zh, this message translates to:
  /// **'让声音慢慢停下'**
  String get sleepTimerTitle;

  /// No description provided for @sleepTimerBody.
  ///
  /// In zh, this message translates to:
  /// **'最后 30 秒会轻轻淡出。也可以不定时。'**
  String get sleepTimerBody;

  /// No description provided for @minutesLabel.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟'**
  String minutesLabel(int minutes);

  /// No description provided for @noTimer.
  ///
  /// In zh, this message translates to:
  /// **'不定时'**
  String get noTimer;

  /// No description provided for @playerCompleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'声音已经慢慢停下'**
  String get playerCompleteTitle;

  /// No description provided for @playerNightCompleteBody.
  ///
  /// In zh, this message translates to:
  /// **'如果困意还在，就让屏幕暗下去。如果反而更清醒，可以到昏暗、安静的地方坐一会儿，困意回来再上床。'**
  String get playerNightCompleteBody;

  /// No description provided for @playerCompleteBody.
  ///
  /// In zh, this message translates to:
  /// **'声音停在这里。让屏幕暗下来，继续休息。'**
  String get playerCompleteBody;

  /// No description provided for @playerNightBody.
  ///
  /// In zh, this message translates to:
  /// **'把音量放轻，让声音留在背景里。'**
  String get playerNightBody;

  /// No description provided for @useOfflineFallback.
  ///
  /// In zh, this message translates to:
  /// **'改用离线的「{title}」'**
  String useOfflineFallback(String title);

  /// No description provided for @playingCandidate.
  ///
  /// In zh, this message translates to:
  /// **'正在播放无广告候选音频'**
  String get playingCandidate;

  /// No description provided for @playingAudio.
  ///
  /// In zh, this message translates to:
  /// **'正在播放无广告音频'**
  String get playingAudio;

  /// No description provided for @tapToPreview.
  ///
  /// In zh, this message translates to:
  /// **'轻触试听'**
  String get tapToPreview;

  /// No description provided for @tapToPlay.
  ///
  /// In zh, this message translates to:
  /// **'轻触播放'**
  String get tapToPlay;

  /// No description provided for @setFadeTimer.
  ///
  /// In zh, this message translates to:
  /// **'设置淡出时间'**
  String get setFadeTimer;

  /// No description provided for @fadeTimerSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置定时淡出'**
  String get fadeTimerSet;

  /// No description provided for @quietFinish.
  ///
  /// In zh, this message translates to:
  /// **'安静结束'**
  String get quietFinish;

  /// No description provided for @stopHere.
  ///
  /// In zh, this message translates to:
  /// **'先到这里'**
  String get stopHere;

  /// No description provided for @playbackLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂时没能载入这段声音，可以换一个试试。'**
  String get playbackLoadFailed;

  /// No description provided for @playbackInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'声音载入被打断了，可以稍后再试。'**
  String get playbackInterrupted;

  /// No description provided for @playbackUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'这段声音暂时不可用，可以换一个试试。'**
  String get playbackUnavailable;

  /// No description provided for @playbackStoppedRetry.
  ///
  /// In zh, this message translates to:
  /// **'播放中断了，可以重新播放或换一个声音。'**
  String get playbackStoppedRetry;

  /// No description provided for @playbackStopped.
  ///
  /// In zh, this message translates to:
  /// **'播放中断了，可以换一个声音试试。'**
  String get playbackStopped;

  /// No description provided for @nightPresetLibraryTitle.
  ///
  /// In zh, this message translates to:
  /// **'夜里醒来时\n默认放哪一段'**
  String get nightPresetLibraryTitle;

  /// No description provided for @nightPresetLibrarySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'选一段熟悉的声音，之后仍可更换。'**
  String get nightPresetLibrarySubtitle;

  /// No description provided for @nightStartFailed.
  ///
  /// In zh, this message translates to:
  /// **'这段声音暂时没能开始，可以换一段再试。'**
  String get nightStartFailed;

  /// No description provided for @nightAwakeHeading.
  ///
  /// In zh, this message translates to:
  /// **'夜里醒来了。'**
  String get nightAwakeHeading;

  /// No description provided for @nightAwakeBody.
  ///
  /// In zh, this message translates to:
  /// **'先让身体和注意力慢慢落稳。'**
  String get nightAwakeBody;

  /// No description provided for @nightReady.
  ///
  /// In zh, this message translates to:
  /// **'准备播放 · {title}'**
  String nightReady(String title);

  /// No description provided for @nightChangePreset.
  ///
  /// In zh, this message translates to:
  /// **'换一段夜醒预设'**
  String get nightChangePreset;

  /// No description provided for @nightStart.
  ///
  /// In zh, this message translates to:
  /// **'帮我慢慢安静下来'**
  String get nightStart;

  /// No description provided for @nightPhysicalNeeds.
  ///
  /// In zh, this message translates to:
  /// **'如果有疼痛、呼吸不适或需要如厕，请先照顾身体。'**
  String get nightPhysicalNeeds;

  /// No description provided for @morningRestedSummary.
  ///
  /// In zh, this message translates to:
  /// **'今天似乎恢复得还不错。'**
  String get morningRestedSummary;

  /// No description provided for @morningOrdinarySummary.
  ///
  /// In zh, this message translates to:
  /// **'今天的恢复感比较普通。'**
  String get morningOrdinarySummary;

  /// No description provided for @morningTiredSummary.
  ///
  /// In zh, this message translates to:
  /// **'昨晚似乎没有休息得很舒服。'**
  String get morningTiredSummary;

  /// No description provided for @morningTitle.
  ///
  /// In zh, this message translates to:
  /// **'醒来以后，\n感觉怎么样？'**
  String get morningTitle;

  /// No description provided for @morningSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'只凭现在的感觉选一个。没有标准答案。'**
  String get morningSubtitle;

  /// No description provided for @feelingRested.
  ///
  /// In zh, this message translates to:
  /// **'挺有精神'**
  String get feelingRested;

  /// No description provided for @feelingOrdinary.
  ///
  /// In zh, this message translates to:
  /// **'还算普通'**
  String get feelingOrdinary;

  /// No description provided for @feelingTired.
  ///
  /// In zh, this message translates to:
  /// **'还是有点累'**
  String get feelingTired;

  /// No description provided for @morningSubjectiveOnly.
  ///
  /// In zh, this message translates to:
  /// **'这是你此刻的主观感受，不是睡眠分数。'**
  String get morningSubjectiveOnly;

  /// No description provided for @morningSaving.
  ///
  /// In zh, this message translates to:
  /// **'正在轻轻留在这台设备中…'**
  String get morningSaving;

  /// No description provided for @morningSaved.
  ///
  /// In zh, this message translates to:
  /// **'这是主观感受，不是睡眠分数。已留在这台设备中，最多保留 30 天。'**
  String get morningSaved;

  /// No description provided for @morningDreamTitle.
  ///
  /// In zh, this message translates to:
  /// **'还记得昨晚的梦吗？'**
  String get morningDreamTitle;

  /// No description provided for @morningDreamBody.
  ///
  /// In zh, this message translates to:
  /// **'写几个画面，得到一份轻松的娱乐解析。'**
  String get morningDreamBody;

  /// No description provided for @morningDreamAction.
  ///
  /// In zh, this message translates to:
  /// **'看看我的梦'**
  String get morningDreamAction;

  /// No description provided for @dreamTitle.
  ///
  /// In zh, this message translates to:
  /// **'梦里发生了\n什么？'**
  String get dreamTitle;

  /// No description provided for @dreamSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'写下几个还记得的画面、人物或感受。'**
  String get dreamSubtitle;

  /// No description provided for @dreamHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：我在一座陌生的房子里，窗外一直下雨……'**
  String get dreamHint;

  /// No description provided for @dreamAction.
  ///
  /// In zh, this message translates to:
  /// **'看看这个梦'**
  String get dreamAction;

  /// No description provided for @dreamPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'文字只在当前页面内即时分析，退出后不保存。'**
  String get dreamPrivacy;

  /// No description provided for @dreamReadingTitle.
  ///
  /// In zh, this message translates to:
  /// **'一种轻松的读法'**
  String get dreamReadingTitle;

  /// No description provided for @dreamDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'仅供休闲娱乐。梦没有统一答案，本解析不预测未来，也不代表心理诊断。'**
  String get dreamDisclaimer;

  /// No description provided for @privacyClearTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除全部睡眠记录？'**
  String get privacyClearTitle;

  /// No description provided for @privacyClearBody.
  ///
  /// In zh, this message translates to:
  /// **'会从这台设备中移除声音陪伴、晨间感受和已同步的健康记录。收藏、个性化偏好和“我的声音”不会受影响。'**
  String get privacyClearBody;

  /// No description provided for @clearAll.
  ///
  /// In zh, this message translates to:
  /// **'全部清除'**
  String get clearAll;

  /// No description provided for @historyCleared.
  ///
  /// In zh, this message translates to:
  /// **'这台设备中的睡眠记录已经清除。'**
  String get historyCleared;

  /// No description provided for @privacyTitle.
  ///
  /// In zh, this message translates to:
  /// **'数据与隐私'**
  String get privacyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In zh, this message translates to:
  /// **'Stillow 没有账号、网站、服务端或云端同步。以下内容只留在这台设备中，也不会进入系统云备份。'**
  String get privacyIntro;

  /// No description provided for @privacyLocalTitle.
  ///
  /// In zh, this message translates to:
  /// **'极简本地记录'**
  String get privacyLocalTitle;

  /// No description provided for @privacyLocalBody.
  ///
  /// In zh, this message translates to:
  /// **'最多保存 30 天的声音陪伴、播放时长、睡前或夜醒场景，以及你主动选择的晨间感受。卸载或换机后不会恢复。'**
  String get privacyLocalBody;

  /// No description provided for @privacyUserSoundsTitle.
  ///
  /// In zh, this message translates to:
  /// **'你添加的声音'**
  String get privacyUserSoundsTitle;

  /// No description provided for @privacyUserSoundsBody.
  ///
  /// In zh, this message translates to:
  /// **'只保存你选出的文件路径，不再把音频复制进 App。不上传。从列表删除时不会删掉手机里原来的文件。以前已经复制过的副本仍会随删除或卸载一起清掉。'**
  String get privacyUserSoundsBody;

  /// No description provided for @privacyHealthTitle.
  ///
  /// In zh, this message translates to:
  /// **'健康数据需要你主动连接'**
  String get privacyHealthTitle;

  /// No description provided for @privacyHealthBody.
  ///
  /// In zh, this message translates to:
  /// **'只保存睡眠时段和阶段；不保留健康记录 UUID、来源设备名、心率或 HRV，不写入健康平台，不后台同步。断开后会清除 App 中的健康缓存。'**
  String get privacyHealthBody;

  /// No description provided for @privacyDreamTitle.
  ///
  /// In zh, this message translates to:
  /// **'梦境文字不保存'**
  String get privacyDreamTitle;

  /// No description provided for @privacyDreamBody.
  ///
  /// In zh, this message translates to:
  /// **'梦境解析只在当前页面完成。退出解析页后，输入的梦境文字不会写入本地记录。'**
  String get privacyDreamBody;

  /// No description provided for @privacyTrendTitle.
  ///
  /// In zh, this message translates to:
  /// **'趋势不是诊断'**
  String get privacyTrendTitle;

  /// No description provided for @privacyTrendBody.
  ///
  /// In zh, this message translates to:
  /// **'设备记录和晨间感受只用于轻松回顾，不生成医学睡眠评分，也不用于诊断或治疗。'**
  String get privacyTrendBody;

  /// No description provided for @clearSleepHistory.
  ///
  /// In zh, this message translates to:
  /// **'清除全部睡眠记录'**
  String get clearSleepHistory;

  /// No description provided for @reviewProfessionalTitle.
  ///
  /// In zh, this message translates to:
  /// **'值得请专业人士一起看看'**
  String get reviewProfessionalTitle;

  /// No description provided for @reviewObserveTitle.
  ///
  /// In zh, this message translates to:
  /// **'先继续观察一段时间'**
  String get reviewObserveTitle;

  /// No description provided for @reviewProfessionalBody.
  ///
  /// In zh, this message translates to:
  /// **'你的选择里出现了持续、频繁或已经影响白天状态的信号。预约睡眠门诊、全科或熟悉睡眠问题的专业人士，会比继续只换声音更合适。'**
  String get reviewProfessionalBody;

  /// No description provided for @reviewObserveBody.
  ///
  /// In zh, this message translates to:
  /// **'这些选择还不足以说明是慢性失眠。可以继续留意自己的实际感受；如果困扰加重，或你只是希望有人一起梳理，也随时可以咨询专业人士。'**
  String get reviewObserveBody;

  /// No description provided for @reviewClinicalContext.
  ///
  /// In zh, this message translates to:
  /// **'临床评估通常会一起考虑：困难是否每周大约 3 晚或更多、是否持续约 3 个月或更久、白天是否受影响，以及是否已经有足够的睡眠时间和合适环境。这里没有做诊断，也没有生成分数。'**
  String get reviewClinicalContext;

  /// No description provided for @reviewSleepOpportunityNote.
  ///
  /// In zh, this message translates to:
  /// **'你也提到最近常常没有留出足够睡眠时间。先尽量照顾这个现实条件会有帮助；如果做不到或白天已经很难受，同样可以向专业人士求助。'**
  String get reviewSleepOpportunityNote;

  /// No description provided for @reviewBreathingSafety.
  ///
  /// In zh, this message translates to:
  /// **'如果经常憋醒、喘醒、被观察到呼吸暂停，或困倦已经影响驾驶安全，请尽早就医确认。'**
  String get reviewBreathingSafety;

  /// No description provided for @reviewTreatmentNote.
  ///
  /// In zh, this message translates to:
  /// **'专业评估可能讨论 CBT-I、其他睡眠问题和必要时的药物；药物不是 App 自动给出的默认答案。'**
  String get reviewTreatmentNote;

  /// No description provided for @understood.
  ///
  /// In zh, this message translates to:
  /// **'我知道了'**
  String get understood;

  /// No description provided for @reviewDismiss.
  ///
  /// In zh, this message translates to:
  /// **'暂不回顾'**
  String get reviewDismiss;

  /// No description provided for @reviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'一起轻轻回顾一下'**
  String get reviewTitle;

  /// No description provided for @reviewIntro.
  ///
  /// In zh, this message translates to:
  /// **'这不是考试，也不会给你贴标签。可以只选愿意回答的；选择仅用于当前页面，退出后不保存。'**
  String get reviewIntro;

  /// No description provided for @reviewDurationQuestion.
  ///
  /// In zh, this message translates to:
  /// **'这样的入睡或夜醒困难，大概持续多久了？'**
  String get reviewDurationQuestion;

  /// No description provided for @reviewUnderMonth.
  ///
  /// In zh, this message translates to:
  /// **'不到 1 个月'**
  String get reviewUnderMonth;

  /// No description provided for @reviewOneToThreeMonths.
  ///
  /// In zh, this message translates to:
  /// **'1～3 个月'**
  String get reviewOneToThreeMonths;

  /// No description provided for @reviewThreeMonths.
  ///
  /// In zh, this message translates to:
  /// **'3 个月以上'**
  String get reviewThreeMonths;

  /// No description provided for @reviewUnsure.
  ///
  /// In zh, this message translates to:
  /// **'不太确定'**
  String get reviewUnsure;

  /// No description provided for @reviewFrequencyQuestion.
  ///
  /// In zh, this message translates to:
  /// **'最近一周里，大概有几个晚上会遇到？'**
  String get reviewFrequencyQuestion;

  /// No description provided for @reviewLessThanWeekly.
  ///
  /// In zh, this message translates to:
  /// **'不到每周一次'**
  String get reviewLessThanWeekly;

  /// No description provided for @reviewOneTwoNights.
  ///
  /// In zh, this message translates to:
  /// **'每周 1～2 晚'**
  String get reviewOneTwoNights;

  /// No description provided for @reviewThreeNights.
  ///
  /// In zh, this message translates to:
  /// **'每周 3 晚或更多'**
  String get reviewThreeNights;

  /// No description provided for @reviewFrequencyUnsure.
  ///
  /// In zh, this message translates to:
  /// **'说不准'**
  String get reviewFrequencyUnsure;

  /// No description provided for @reviewDaytimeQuestion.
  ///
  /// In zh, this message translates to:
  /// **'它对白天的精神、注意力或情绪有什么影响？'**
  String get reviewDaytimeQuestion;

  /// No description provided for @reviewImpactLittle.
  ///
  /// In zh, this message translates to:
  /// **'几乎没有'**
  String get reviewImpactLittle;

  /// No description provided for @reviewImpactNoticeable.
  ///
  /// In zh, this message translates to:
  /// **'能感觉到一些'**
  String get reviewImpactNoticeable;

  /// No description provided for @reviewImpactClear.
  ///
  /// In zh, this message translates to:
  /// **'影响比较明显或涉及安全'**
  String get reviewImpactClear;

  /// No description provided for @reviewOpportunityQuestion.
  ///
  /// In zh, this message translates to:
  /// **'通常已经留出了够用的睡眠时间和相对合适的环境吗？'**
  String get reviewOpportunityQuestion;

  /// No description provided for @reviewOpportunityEnough.
  ///
  /// In zh, this message translates to:
  /// **'大多数时候有'**
  String get reviewOpportunityEnough;

  /// No description provided for @reviewOpportunityVaries.
  ///
  /// In zh, this message translates to:
  /// **'有时有，有时没有'**
  String get reviewOpportunityVaries;

  /// No description provided for @reviewOpportunityNotEnough.
  ///
  /// In zh, this message translates to:
  /// **'大多数时候没有'**
  String get reviewOpportunityNotEnough;

  /// No description provided for @reviewShowResult.
  ///
  /// In zh, this message translates to:
  /// **'这样就好，看看说明'**
  String get reviewShowResult;

  /// No description provided for @reviewSkip.
  ///
  /// In zh, this message translates to:
  /// **'先不回顾'**
  String get reviewSkip;

  /// No description provided for @healthPermissionTitle.
  ///
  /// In zh, this message translates to:
  /// **'只读最近的睡眠记录'**
  String get healthPermissionTitle;

  /// No description provided for @healthPermissionBody.
  ///
  /// In zh, this message translates to:
  /// **'接下来系统会询问是否允许读取睡眠时段和睡眠阶段。Stillow 不读取心率或 HRV，不写入健康数据，也不在后台同步。'**
  String get healthPermissionBody;

  /// No description provided for @healthNotNow.
  ///
  /// In zh, this message translates to:
  /// **'先不连接'**
  String get healthNotNow;

  /// No description provided for @healthInstallReturn.
  ///
  /// In zh, this message translates to:
  /// **'安装或更新完成后，回到这里再连接就好。'**
  String get healthInstallReturn;

  /// No description provided for @healthDisconnectTitle.
  ///
  /// In zh, this message translates to:
  /// **'断开健康数据？'**
  String get healthDisconnectTitle;

  /// No description provided for @healthDisconnectIosBody.
  ///
  /// In zh, this message translates to:
  /// **'会清除 Stillow 保存的健康记录。Apple 健康的读取权限仍需在系统“健康”中管理。'**
  String get healthDisconnectIosBody;

  /// No description provided for @healthDisconnectAndroidBody.
  ///
  /// In zh, this message translates to:
  /// **'会撤销 Stillow 的 Health Connect 权限，并清除 App 中保存的健康记录。'**
  String get healthDisconnectAndroidBody;

  /// No description provided for @healthDisconnectAction.
  ///
  /// In zh, this message translates to:
  /// **'断开并清除'**
  String get healthDisconnectAction;

  /// No description provided for @healthDisconnectedIos.
  ///
  /// In zh, this message translates to:
  /// **'App 内的健康记录已清除；系统授权可在 Apple 健康中管理。'**
  String get healthDisconnectedIos;

  /// No description provided for @healthDisconnectedAndroid.
  ///
  /// In zh, this message translates to:
  /// **'Health Connect 已断开，本机缓存也已清除。'**
  String get healthDisconnectedAndroid;

  /// No description provided for @historyRemoveNightTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除这晚的本地记录？'**
  String get historyRemoveNightTitle;

  /// No description provided for @historyRemoveNightBody.
  ///
  /// In zh, this message translates to:
  /// **'只会移除 Stillow 的声音陪伴记录和晨间感受，不会影响系统健康数据。'**
  String get historyRemoveNightBody;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @historyClearTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除 Stillow 中的全部记录？'**
  String get historyClearTitle;

  /// No description provided for @historyClearBody.
  ///
  /// In zh, this message translates to:
  /// **'声音陪伴、晨间感受和已同步的健康记录都会从这台设备中移除。收藏和个性化偏好不会受影响。'**
  String get historyClearBody;

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'最近的夜晚'**
  String get historyTitle;

  /// No description provided for @historyIntro.
  ///
  /// In zh, this message translates to:
  /// **'只帮助你回顾，不给睡眠打分。记录最多保留 30 天。'**
  String get historyIntro;

  /// No description provided for @localHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'Stillow 本地记录'**
  String get localHistoryTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有本地记录。播放一段声音，或在醒来后选一下感受，这里才会慢慢出现内容。'**
  String get historyEmpty;

  /// No description provided for @healthLastUpdated.
  ///
  /// In zh, this message translates to:
  /// **'上次更新：{date}'**
  String healthLastUpdated(String date);

  /// No description provided for @healthOptional.
  ///
  /// In zh, this message translates to:
  /// **'由你决定是否连接，不会在首次启动时询问。'**
  String get healthOptional;

  /// No description provided for @healthInstallRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要先安装或更新 Health Connect。'**
  String get healthInstallRequired;

  /// No description provided for @healthUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'这台设备暂时不支持系统睡眠数据。'**
  String get healthUnavailable;

  /// No description provided for @healthCardTitle.
  ///
  /// In zh, this message translates to:
  /// **'手表与系统睡眠记录'**
  String get healthCardTitle;

  /// No description provided for @healthConnectSync.
  ///
  /// In zh, this message translates to:
  /// **'连接并同步'**
  String get healthConnectSync;

  /// No description provided for @healthUpdate.
  ///
  /// In zh, this message translates to:
  /// **'更新最近记录'**
  String get healthUpdate;

  /// No description provided for @healthInstall.
  ///
  /// In zh, this message translates to:
  /// **'安装或更新 Health Connect'**
  String get healthInstall;

  /// No description provided for @healthDisconnectCache.
  ///
  /// In zh, this message translates to:
  /// **'断开并清除健康缓存'**
  String get healthDisconnectCache;

  /// No description provided for @healthTrendTitle.
  ///
  /// In zh, this message translates to:
  /// **'睡眠记录时段走势'**
  String get healthTrendTitle;

  /// No description provided for @healthTrendBody.
  ///
  /// In zh, this message translates to:
  /// **'连接线表示设备记录的起止跨度，不是睡眠质量分数。'**
  String get healthTrendBody;

  /// No description provided for @healthDeviceRecords.
  ///
  /// In zh, this message translates to:
  /// **'设备记录'**
  String get healthDeviceRecords;

  /// No description provided for @healthStagesAvailable.
  ///
  /// In zh, this message translates to:
  /// **'设备同时提供了睡眠阶段'**
  String get healthStagesAvailable;

  /// No description provided for @healthTimelineSemantics.
  ///
  /// In zh, this message translates to:
  /// **'设备提供的睡眠阶段时间条，仅供回顾，不是睡眠评分'**
  String get healthTimelineSemantics;

  /// No description provided for @healthTimelineLegend.
  ///
  /// In zh, this message translates to:
  /// **'浅睡 · 深睡 · REM · 清醒（按设备记录展示）'**
  String get healthTimelineLegend;

  /// No description provided for @historyMorningFeeling.
  ///
  /// In zh, this message translates to:
  /// **'醒来时：{feeling}'**
  String historyMorningFeeling(String feeling);

  /// No description provided for @historyNightSession.
  ///
  /// In zh, this message translates to:
  /// **'夜醒陪伴'**
  String get historyNightSession;

  /// No description provided for @historyBedtimeSession.
  ///
  /// In zh, this message translates to:
  /// **'睡前陪伴'**
  String get historyBedtimeSession;

  /// No description provided for @historySessionLine.
  ///
  /// In zh, this message translates to:
  /// **'{context} · {duration}'**
  String historySessionLine(String context, String duration);

  /// No description provided for @historyRemoveNightTooltip.
  ///
  /// In zh, this message translates to:
  /// **'移除这晚的本地记录'**
  String get historyRemoveNightTooltip;

  /// No description provided for @durationMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小时'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小时 {minutes} 分钟'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @healthSyncUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'这台设备暂时不能读取系统睡眠记录。'**
  String get healthSyncUnavailable;

  /// No description provided for @healthSyncPermissionDeclined.
  ///
  /// In zh, this message translates to:
  /// **'没有取得读取权限。以后想连接时，再从这里开始就好。'**
  String get healthSyncPermissionDeclined;

  /// No description provided for @healthSyncNoData.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天没有读到睡眠记录，也可能是系统没有开放读取。'**
  String get healthSyncNoData;

  /// No description provided for @healthSyncSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已更新这台设备中的最近记录。'**
  String get healthSyncSuccess;

  /// No description provided for @healthSyncFailedUnlocked.
  ///
  /// In zh, this message translates to:
  /// **'这次没有同步好。设备解锁后再试也可以。'**
  String get healthSyncFailedUnlocked;

  /// No description provided for @healthSyncFailed.
  ///
  /// In zh, this message translates to:
  /// **'这次没有同步好，稍后再试也可以。'**
  String get healthSyncFailed;

  /// No description provided for @userSoundsTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的声音'**
  String get userSoundsTitle;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @userSoundsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'列表里的会按顺序播放。不想听了，从列表拿掉就行。'**
  String get userSoundsSubtitle;

  /// No description provided for @userSoundsUsage.
  ///
  /// In zh, this message translates to:
  /// **'{count}/20 个 · 已用 {used} MB'**
  String userSoundsUsage(int count, String used);

  /// No description provided for @userSoundsHomeTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的声音'**
  String get userSoundsHomeTitle;

  /// No description provided for @userSoundsHomeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'加入的会按列表播放；不想听了就拿掉。'**
  String get userSoundsHomeSubtitle;

  /// No description provided for @userSoundsEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'这里还没有声音'**
  String get userSoundsEmptyTitle;

  /// No description provided for @userSoundsEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'可以一次加入多条熟悉的音乐、课程或朗读。只记下路径，按列表播放；不想听了从列表拿掉即可。'**
  String get userSoundsEmptyBody;

  /// No description provided for @userSoundsAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加声音'**
  String get userSoundsAdd;

  /// No description provided for @userSoundsPlayList.
  ///
  /// In zh, this message translates to:
  /// **'按列表播放'**
  String get userSoundsPlayList;

  /// No description provided for @userSoundsPrevious.
  ///
  /// In zh, this message translates to:
  /// **'上一首'**
  String get userSoundsPrevious;

  /// No description provided for @userSoundsNext.
  ///
  /// In zh, this message translates to:
  /// **'下一首'**
  String get userSoundsNext;

  /// No description provided for @userSoundsPlaylistPosition.
  ///
  /// In zh, this message translates to:
  /// **'{current} / {total}'**
  String userSoundsPlaylistPosition(int current, int total);

  /// No description provided for @userSoundsImportTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加本机音频'**
  String get userSoundsImportTitle;

  /// No description provided for @userSoundsImportNotice.
  ///
  /// In zh, this message translates to:
  /// **'请选择你有权使用的 MP3 或 M4A 文件，可以一次选多个。Stillow 只保存路径，按加入顺序排成列表，不会复制或上传。不想听了从列表拿掉即可，不会删掉手机里原来的文件。最多保留 20 个。'**
  String get userSoundsImportNotice;

  /// No description provided for @userSoundsChooseFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get userSoundsChooseFile;

  /// No description provided for @userSoundsImporting.
  ///
  /// In zh, this message translates to:
  /// **'正在添加…'**
  String get userSoundsImporting;

  /// No description provided for @userSoundsCancelImport.
  ///
  /// In zh, this message translates to:
  /// **'取消添加'**
  String get userSoundsCancelImport;

  /// No description provided for @userSoundsImportCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消添加。'**
  String get userSoundsImportCancelled;

  /// No description provided for @userSoundsUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'目前只支持 MP3 和 M4A 文件。'**
  String get userSoundsUnsupported;

  /// No description provided for @userSoundsEmptyFile.
  ///
  /// In zh, this message translates to:
  /// **'这个文件没有可播放的内容。'**
  String get userSoundsEmptyFile;

  /// No description provided for @userSoundsLibraryFull.
  ///
  /// In zh, this message translates to:
  /// **'最多可以保留 20 个声音。'**
  String get userSoundsLibraryFull;

  /// No description provided for @userSoundsSourceUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'没有读到这个文件，请重新选择。'**
  String get userSoundsSourceUnavailable;

  /// No description provided for @userSoundsImportInProgress.
  ///
  /// In zh, this message translates to:
  /// **'另一个声音正在添加。'**
  String get userSoundsImportInProgress;

  /// No description provided for @userSoundsWriteFailed.
  ///
  /// In zh, this message translates to:
  /// **'这次没有保存好，请检查本机空间后重试。'**
  String get userSoundsWriteFailed;

  /// No description provided for @userSoundsEdit.
  ///
  /// In zh, this message translates to:
  /// **'声音设置'**
  String get userSoundsEdit;

  /// No description provided for @userSoundsRename.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get userSoundsRename;

  /// No description provided for @userSoundsLoop.
  ///
  /// In zh, this message translates to:
  /// **'循环播放'**
  String get userSoundsLoop;

  /// No description provided for @userSoundsLoopBody.
  ///
  /// In zh, this message translates to:
  /// **'适合纯音乐或环境声。'**
  String get userSoundsLoopBody;

  /// No description provided for @userSoundsAttenuate.
  ///
  /// In zh, this message translates to:
  /// **'每轮逐渐变轻'**
  String get userSoundsAttenuate;

  /// No description provided for @userSoundsAttenuateBody.
  ///
  /// In zh, this message translates to:
  /// **'循环越久，音量会缓慢降低。'**
  String get userSoundsAttenuateBody;

  /// No description provided for @userSoundsDefaultTimer.
  ///
  /// In zh, this message translates to:
  /// **'默认淡出时间'**
  String get userSoundsDefaultTimer;

  /// No description provided for @userSoundsNoDefaultTimer.
  ///
  /// In zh, this message translates to:
  /// **'不自动停止'**
  String get userSoundsNoDefaultTimer;

  /// No description provided for @userSoundsSave.
  ///
  /// In zh, this message translates to:
  /// **'保存设置'**
  String get userSoundsSave;

  /// No description provided for @userSoundsDelete.
  ///
  /// In zh, this message translates to:
  /// **'从列表拿掉'**
  String get userSoundsDelete;

  /// No description provided for @userSoundsDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'从播放列表拿掉？'**
  String get userSoundsDeleteTitle;

  /// No description provided for @userSoundsDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'拿掉后不再播放。手机里原来的文件还在。'**
  String get userSoundsDeleteBody;

  /// No description provided for @userSoundsRemoveFromList.
  ///
  /// In zh, this message translates to:
  /// **'从列表拿掉'**
  String get userSoundsRemoveFromList;

  /// No description provided for @userSoundLocalBadge.
  ///
  /// In zh, this message translates to:
  /// **'我的声音 · 仅保存在本机'**
  String get userSoundLocalBadge;

  /// No description provided for @userSoundLocalSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'来自你的本机音频'**
  String get userSoundLocalSubtitle;

  /// No description provided for @userSoundLocalShortLabel.
  ///
  /// In zh, this message translates to:
  /// **'我的声音'**
  String get userSoundLocalShortLabel;

  /// No description provided for @userSoundLocalCreator.
  ///
  /// In zh, this message translates to:
  /// **'本机文件'**
  String get userSoundLocalCreator;

  /// No description provided for @userSoundsSaved.
  ///
  /// In zh, this message translates to:
  /// **'设置已保存。'**
  String get userSoundsSaved;

  /// No description provided for @userSoundsOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'这次操作没有完成，请稍后重试。'**
  String get userSoundsOperationFailed;

  /// No description provided for @nightPresetPersonalTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的声音'**
  String get nightPresetPersonalTitle;

  /// No description provided for @nightPresetBuiltInTitle.
  ///
  /// In zh, this message translates to:
  /// **'Stillow 声音'**
  String get nightPresetBuiltInTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
