// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Stillow';

  @override
  String get back => '返回';

  @override
  String get close => '关闭';

  @override
  String get finish => '结束';

  @override
  String get continueLabel => '继续';

  @override
  String get keepForNow => '先留着';

  @override
  String get clear => '清空';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get onboardingSkip => '先随便听听';

  @override
  String get onboardingKeep => '保留现在';

  @override
  String get onboardingTryTonight => '今晚先试试';

  @override
  String get onboardingNeedTitle => '今晚，你更希望得到哪种陪伴？';

  @override
  String get onboardingNeedSubtitle => '凭第一感觉，选最接近此刻的一项。';

  @override
  String get needQuietMind => '想法停不下来';

  @override
  String get needNotSleepy => '脑袋没想什么，但还不困';

  @override
  String get needSleepPressure => '越想赶快睡，反而越清醒';

  @override
  String get needRelaxBody => '让身体松下来';

  @override
  String get needMaskNoise => '把周围动静放远一点';

  @override
  String get needNightAwake => '夜里醒来后，不容易再睡';

  @override
  String get needGentleCompany => '说不上来，只想有人陪一会儿';

  @override
  String get onboardingSoundTitle => '什么声音会让你舒服一些？';

  @override
  String get onboardingSoundSubtitle => '先选此刻更喜欢的声音，之后随时可以更换。';

  @override
  String get soundSoftVoice => '轻柔的人声或中文朗读';

  @override
  String get soundFamiliarMusic => '熟悉、平缓的音乐';

  @override
  String get soundNature => '雨声、风声等环境声';

  @override
  String get soundMinimal => '更喜欢安静，只要少量提示';

  @override
  String get onboardingGuidanceTitle => '你喜欢怎样的陪伴？';

  @override
  String get onboardingGuidanceSubtitle => '选择更喜欢的陪伴程度。';

  @override
  String get guidanceStepByStep => '带着我一步步放松';

  @override
  String get guidanceOccasional => '偶尔提醒一下就好';

  @override
  String get guidanceAmbientOnly => '只听声音，保持安静';

  @override
  String get homeSettingsTooltip => '设置与关于 Stillow';

  @override
  String get homeGreeting => '今晚，\n慢一点。';

  @override
  String get homePrompt => '选一段此刻喜欢的声音。';

  @override
  String get homeDifferentTonight => '今晚感觉有点不同';

  @override
  String get homeOtherWays => '想换一种方式';

  @override
  String get homeBrowseTitle => '看看其他陪伴';

  @override
  String get homeBrowseSubtitle => '搜索、分类、收藏，或把在线声音留到设备里';

  @override
  String get homeCandidatesTitle => '试听候选声音';

  @override
  String homeCandidatesSubtitle(int count) {
    return '$count 段公开候选，需要联网，听感仍在筛选中';
  }

  @override
  String get candidateLibraryTitle => '候选声音\n试听列表';

  @override
  String get candidateLibrarySubtitle => '可以搜索、收藏，或下载到设备后慢慢听。';

  @override
  String get homeVoiceTitle => '听一段舒缓人声';

  @override
  String get homeVoiceSubtitle => '按语言偏好选择舒缓朗读与轻声内容';

  @override
  String get voiceLibraryTitle => '舒缓人声';

  @override
  String get voiceLibrarySubtitle => '选择更喜欢的音色和篇幅。';

  @override
  String get homeKnowledgeTitle => '听一段平缓的知识';

  @override
  String get homeKnowledgeSubtitle => '课程、百科与技术朗读，按声音和篇幅挑一段';

  @override
  String get knowledgeLibraryTitle => '知识陪伴';

  @override
  String get knowledgeLibrarySubtitle => '选择更喜欢的声音、主题和篇幅。';

  @override
  String get homeNightAwakeTitle => '夜里醒来时';

  @override
  String get homeNightAwakeSubtitle => '不看时间，一键开始预设陪伴';

  @override
  String get homeMorningTitle => '醒来以后';

  @override
  String get homeMorningSubtitle => '看看此刻的恢复感，或者轻松聊聊昨晚的梦';

  @override
  String get homeHistoryTitle => '最近的夜晚';

  @override
  String get homeHistorySubtitle => '回顾本地记录，或主动连接手表与系统睡眠数据';

  @override
  String get homeFooter => '想用时再来。';

  @override
  String get aboutTagline => '陪你慢慢安静。';

  @override
  String get aboutPrototypeNotice =>
      'Stillow 当前是体验原型，不用于诊断或治疗睡眠疾病。如果经常憋醒、呼吸暂停，或白天困倦已经影响驾驶安全，更适合先找专业人士确认。';

  @override
  String get interfaceLanguageTitle => '界面语言';

  @override
  String get interfaceLanguageDescription => '默认跟随系统，也可以在这里单独选择。';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get audioLanguageTitle => '人声音频语言';

  @override
  String get audioLanguageDescription => '无人声音频始终可用；人声内容按这里的偏好筛选。';

  @override
  String get audioLanguageAutomatic => '跟随界面';

  @override
  String get audioLanguageChinese => '中文人声';

  @override
  String get audioLanguageEnglish => '英文人声';

  @override
  String get audioLanguageAny => '全部语言';

  @override
  String get contentRegionTitle => '素材区域';

  @override
  String get contentRegionDescription => '自动模式会跟随设备地区；也可以手动切换，随时改回来。';

  @override
  String get contentRegionAutomaticChina => '自动 · 国内';

  @override
  String get contentRegionAutomaticInternational => '自动 · 国际';

  @override
  String get contentRegionChina => '国内素材';

  @override
  String get contentRegionInternational => '国际素材';

  @override
  String get adjustPreferences => '调整陪伴偏好';

  @override
  String get dataAndPrivacy => '数据与隐私';

  @override
  String get viewLatestVersion => '查看最新版本';

  @override
  String get releaseNotes => '版本与更新说明';

  @override
  String get githubOpenFailed => '暂时没能打开 GitHub，可以稍后再试。';

  @override
  String get recommendationTryTonight => '今晚先试试';

  @override
  String get supportDifferentPathTitle => '换条完全不同的路试试';

  @override
  String get supportProfessionalTitle => '声音可能不是全部答案';

  @override
  String get supportDifferentPathBody => '最近试过的声音帮助有限，可以在人声、音乐和自然声之间换一种感受。';

  @override
  String get supportProfessionalBody => '如果已经多次尝试仍没帮助，可以选择了解什么时候值得找专业人士聊聊。';

  @override
  String get supportLearnMore => '我想了解一下';

  @override
  String get feedbackSaveFailed => '这次反馈没能保存，可以再试一次。';

  @override
  String get feedbackIntro => '有空的时候，告诉我们';

  @override
  String get feedbackBedtimeQuestion => '上次那段陪伴感觉怎么样？';

  @override
  String get feedbackNightQuestion => '夜醒后的那段陪伴呢？';

  @override
  String get feedbackComfortable => '挺舒服的';

  @override
  String get feedbackNightComfortable => '比较容易安静下来';

  @override
  String get feedbackNoDifference => '没有明显区别';

  @override
  String get feedbackNotForMe => '不太适合';

  @override
  String get feedbackNightNotForMe => '反而更清醒';

  @override
  String get tonightStateTitle => '今晚更像是\n哪一种？';

  @override
  String get tonightStateSubtitle => '凭第一感觉，选最接近的一项。';

  @override
  String get stateBusyMind => '想法有点多';

  @override
  String get stateNotSleepy => '没想什么，只是还不困';

  @override
  String get stateSleepPressure => '有点着急，越想睡越清醒';

  @override
  String get stateTenseBody => '身体还没松下来';

  @override
  String get stateNoisyRoom => '周围有点吵';

  @override
  String get stateNightAwake => '是夜里醒来后';

  @override
  String get stateUnsure => '说不上来';

  @override
  String get tonightStateSkip => '跳过，继续熟悉的方式';

  @override
  String get libraryDefaultTitle => '换一种\n舒服的方式';

  @override
  String get libraryDefaultSubtitle => '可以按此刻的感觉更换。';

  @override
  String get downloadComplete => '已经留在这台设备里了。';

  @override
  String get downloadFailed => '这次没下载好，网络方便时再试也可以。';

  @override
  String get downloadCancelled => '这次下载已经停下来了。';

  @override
  String get downloadQuotaExceeded => '设备里的离线声音已经比较多了，先移除一些再下载。';

  @override
  String get cancelDownload => '取消下载';

  @override
  String get removeDownloadTitle => '移除这份离线声音？';

  @override
  String get removeDownloadBody => '只会清理下载文件，不会取消收藏；以后仍可在线播放或重新下载。';

  @override
  String get removeOfflineFile => '移除离线文件';

  @override
  String get librarySearchHint => '搜声音、作者或主题';

  @override
  String get libraryCheckingOffline => '正在看看哪些声音已在设备里…';

  @override
  String libraryAvailableCount(int count) {
    return '$count 段可选';
  }

  @override
  String get filterAll => '全部';

  @override
  String get filterFavorites => '收藏';

  @override
  String get filterAmbient => '环境声';

  @override
  String get filterMusic => '音乐';

  @override
  String get filterVoice => '人声';

  @override
  String get filterCourses => '科普';

  @override
  String get filterOffline => '已离线';

  @override
  String get candidateAwaitingReview => '待试听';

  @override
  String get availableOffline => '离线可用';

  @override
  String get online => '在线';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get favorite => '收藏';

  @override
  String get bundledOffline => '随应用离线提供';

  @override
  String get manageOfflineFile => '管理离线文件';

  @override
  String get downloadToDevice => '下载到设备';

  @override
  String get spokenChinese => '中文';

  @override
  String get spokenEnglish => '英文';

  @override
  String get spokenCantonese => '粤语';

  @override
  String get spokenTraditionalChinese => '繁体中文';

  @override
  String get noSpokenLanguage => '无人声';

  @override
  String get emptyFavorites => '还没有收藏。听到舒服的声音时，轻点小心形就好。';

  @override
  String get emptyLibrary => '这里暂时没有合适的结果，换个词或分类看看。';

  @override
  String get playerCreditsTitle => '这段声音从哪里来';

  @override
  String get viewSource => '查看来源';

  @override
  String get viewLicense => '查看许可';

  @override
  String get sleepTimerTitle => '让声音慢慢停下';

  @override
  String get sleepTimerBody => '最后 30 秒会轻轻淡出。也可以不定时。';

  @override
  String minutesLabel(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get noTimer => '不定时';

  @override
  String get playerCompleteTitle => '声音已经慢慢停下';

  @override
  String get playerNightCompleteBody =>
      '如果困意还在，就让屏幕暗下去。如果反而更清醒，可以到昏暗、安静的地方坐一会儿，困意回来再上床。';

  @override
  String get playerCompleteBody => '声音停在这里。让屏幕暗下来，继续休息。';

  @override
  String get playerNightBody => '把音量放轻，让声音留在背景里。';

  @override
  String useOfflineFallback(String title) {
    return '改用离线的「$title」';
  }

  @override
  String get playingCandidate => '正在播放无广告候选音频';

  @override
  String get playingAudio => '正在播放无广告音频';

  @override
  String get tapToPreview => '轻触试听';

  @override
  String get tapToPlay => '轻触播放';

  @override
  String get setFadeTimer => '设置淡出时间';

  @override
  String get fadeTimerSet => '已设置定时淡出';

  @override
  String get quietFinish => '安静结束';

  @override
  String get stopHere => '先到这里';

  @override
  String get playbackLoadFailed => '暂时没能载入这段声音，可以换一个试试。';

  @override
  String get playbackInterrupted => '声音载入被打断了，可以稍后再试。';

  @override
  String get playbackUnavailable => '这段声音暂时不可用，可以换一个试试。';

  @override
  String get playbackStoppedRetry => '播放中断了，可以重新播放或换一个声音。';

  @override
  String get playbackStopped => '播放中断了，可以换一个声音试试。';

  @override
  String get nightPresetLibraryTitle => '夜里醒来时\n默认放哪一段';

  @override
  String get nightPresetLibrarySubtitle => '选一段熟悉的声音，之后仍可更换。';

  @override
  String get nightStartFailed => '这段声音暂时没能开始，可以换一段再试。';

  @override
  String get nightAwakeHeading => '夜里醒来了。';

  @override
  String get nightAwakeBody => '先让身体和注意力慢慢落稳。';

  @override
  String nightReady(String title) {
    return '准备播放 · $title';
  }

  @override
  String get nightChangePreset => '换一段夜醒预设';

  @override
  String get nightStart => '帮我慢慢安静下来';

  @override
  String get nightPhysicalNeeds => '如果有疼痛、呼吸不适或需要如厕，请先照顾身体。';

  @override
  String get morningRestedSummary => '今天似乎恢复得还不错。';

  @override
  String get morningOrdinarySummary => '今天的恢复感比较普通。';

  @override
  String get morningTiredSummary => '昨晚似乎没有休息得很舒服。';

  @override
  String get morningTitle => '醒来以后，\n感觉怎么样？';

  @override
  String get morningSubtitle => '只凭现在的感觉选一个。没有标准答案。';

  @override
  String get feelingRested => '挺有精神';

  @override
  String get feelingOrdinary => '还算普通';

  @override
  String get feelingTired => '还是有点累';

  @override
  String get morningSubjectiveOnly => '这是你此刻的主观感受，不是睡眠分数。';

  @override
  String get morningSaving => '正在轻轻留在这台设备中…';

  @override
  String get morningSaved => '这是主观感受，不是睡眠分数。已留在这台设备中，最多保留 30 天。';

  @override
  String get morningDreamTitle => '还记得昨晚的梦吗？';

  @override
  String get morningDreamBody => '写几个画面，得到一份轻松的娱乐解析。';

  @override
  String get morningDreamAction => '看看我的梦';

  @override
  String get dreamTitle => '梦里发生了\n什么？';

  @override
  String get dreamSubtitle => '写下几个还记得的画面、人物或感受。';

  @override
  String get dreamHint => '例如：我在一座陌生的房子里，窗外一直下雨……';

  @override
  String get dreamAction => '看看这个梦';

  @override
  String get dreamPrivacy => '文字只在当前页面内即时分析，退出后不保存。';

  @override
  String get dreamReadingTitle => '一种轻松的读法';

  @override
  String get dreamDisclaimer => '仅供休闲娱乐。梦没有统一答案，本解析不预测未来，也不代表心理诊断。';

  @override
  String get privacyClearTitle => '清除全部睡眠记录？';

  @override
  String get privacyClearBody =>
      '会从这台设备中移除声音陪伴、晨间感受和已同步的健康记录。收藏、个性化偏好和“我的声音”不会受影响。';

  @override
  String get clearAll => '全部清除';

  @override
  String get historyCleared => '这台设备中的睡眠记录已经清除。';

  @override
  String get privacyTitle => '数据与隐私';

  @override
  String get privacyIntro =>
      'Stillow 没有账号、网站、服务端或云端同步。以下内容只留在这台设备中，也不会进入系统云备份。';

  @override
  String get privacyLocalTitle => '极简本地记录';

  @override
  String get privacyLocalBody =>
      '最多保存 30 天的声音陪伴、播放时长、睡前或夜醒场景，以及你主动选择的晨间感受。卸载或换机后不会恢复。';

  @override
  String get privacyUserSoundsTitle => '你添加的声音';

  @override
  String get privacyUserSoundsBody =>
      '只保存你选出的文件路径，不再把音频复制进 App。不上传。从列表删除时不会删掉手机里原来的文件。以前已经复制过的副本仍会随删除或卸载一起清掉。';

  @override
  String get privacyHealthTitle => '健康数据需要你主动连接';

  @override
  String get privacyHealthBody =>
      '只保存睡眠时段和阶段；不保留健康记录 UUID、来源设备名、心率或 HRV，不写入健康平台，不后台同步。断开后会清除 App 中的健康缓存。';

  @override
  String get privacyDreamTitle => '梦境文字不保存';

  @override
  String get privacyDreamBody => '梦境解析只在当前页面完成。退出解析页后，输入的梦境文字不会写入本地记录。';

  @override
  String get privacyTrendTitle => '趋势不是诊断';

  @override
  String get privacyTrendBody => '设备记录和晨间感受只用于轻松回顾，不生成医学睡眠评分，也不用于诊断或治疗。';

  @override
  String get clearSleepHistory => '清除全部睡眠记录';

  @override
  String get reviewProfessionalTitle => '值得请专业人士一起看看';

  @override
  String get reviewObserveTitle => '先继续观察一段时间';

  @override
  String get reviewProfessionalBody =>
      '你的选择里出现了持续、频繁或已经影响白天状态的信号。预约睡眠门诊、全科或熟悉睡眠问题的专业人士，会比继续只换声音更合适。';

  @override
  String get reviewObserveBody =>
      '这些选择还不足以说明是慢性失眠。可以继续留意自己的实际感受；如果困扰加重，或你只是希望有人一起梳理，也随时可以咨询专业人士。';

  @override
  String get reviewClinicalContext =>
      '临床评估通常会一起考虑：困难是否每周大约 3 晚或更多、是否持续约 3 个月或更久、白天是否受影响，以及是否已经有足够的睡眠时间和合适环境。这里没有做诊断，也没有生成分数。';

  @override
  String get reviewSleepOpportunityNote =>
      '你也提到最近常常没有留出足够睡眠时间。先尽量照顾这个现实条件会有帮助；如果做不到或白天已经很难受，同样可以向专业人士求助。';

  @override
  String get reviewBreathingSafety => '如果经常憋醒、喘醒、被观察到呼吸暂停，或困倦已经影响驾驶安全，请尽早就医确认。';

  @override
  String get reviewTreatmentNote =>
      '专业评估可能讨论 CBT-I、其他睡眠问题和必要时的药物；药物不是 App 自动给出的默认答案。';

  @override
  String get understood => '我知道了';

  @override
  String get reviewDismiss => '暂不回顾';

  @override
  String get reviewTitle => '一起轻轻回顾一下';

  @override
  String get reviewIntro => '这不是考试，也不会给你贴标签。可以只选愿意回答的；选择仅用于当前页面，退出后不保存。';

  @override
  String get reviewDurationQuestion => '这样的入睡或夜醒困难，大概持续多久了？';

  @override
  String get reviewUnderMonth => '不到 1 个月';

  @override
  String get reviewOneToThreeMonths => '1～3 个月';

  @override
  String get reviewThreeMonths => '3 个月以上';

  @override
  String get reviewUnsure => '不太确定';

  @override
  String get reviewFrequencyQuestion => '最近一周里，大概有几个晚上会遇到？';

  @override
  String get reviewLessThanWeekly => '不到每周一次';

  @override
  String get reviewOneTwoNights => '每周 1～2 晚';

  @override
  String get reviewThreeNights => '每周 3 晚或更多';

  @override
  String get reviewFrequencyUnsure => '说不准';

  @override
  String get reviewDaytimeQuestion => '它对白天的精神、注意力或情绪有什么影响？';

  @override
  String get reviewImpactLittle => '几乎没有';

  @override
  String get reviewImpactNoticeable => '能感觉到一些';

  @override
  String get reviewImpactClear => '影响比较明显或涉及安全';

  @override
  String get reviewOpportunityQuestion => '通常已经留出了够用的睡眠时间和相对合适的环境吗？';

  @override
  String get reviewOpportunityEnough => '大多数时候有';

  @override
  String get reviewOpportunityVaries => '有时有，有时没有';

  @override
  String get reviewOpportunityNotEnough => '大多数时候没有';

  @override
  String get reviewShowResult => '这样就好，看看说明';

  @override
  String get reviewSkip => '先不回顾';

  @override
  String get healthPermissionTitle => '只读最近的睡眠记录';

  @override
  String get healthPermissionBody =>
      '接下来系统会询问是否允许读取睡眠时段和睡眠阶段。Stillow 不读取心率或 HRV，不写入健康数据，也不在后台同步。';

  @override
  String get healthNotNow => '先不连接';

  @override
  String get healthInstallReturn => '安装或更新完成后，回到这里再连接就好。';

  @override
  String get healthDisconnectTitle => '断开健康数据？';

  @override
  String get healthDisconnectIosBody =>
      '会清除 Stillow 保存的健康记录。Apple 健康的读取权限仍需在系统“健康”中管理。';

  @override
  String get healthDisconnectAndroidBody =>
      '会撤销 Stillow 的 Health Connect 权限，并清除 App 中保存的健康记录。';

  @override
  String get healthDisconnectAction => '断开并清除';

  @override
  String get healthDisconnectedIos => 'App 内的健康记录已清除；系统授权可在 Apple 健康中管理。';

  @override
  String get healthDisconnectedAndroid => 'Health Connect 已断开，本机缓存也已清除。';

  @override
  String get historyRemoveNightTitle => '移除这晚的本地记录？';

  @override
  String get historyRemoveNightBody => '只会移除 Stillow 的声音陪伴记录和晨间感受，不会影响系统健康数据。';

  @override
  String get remove => '移除';

  @override
  String get historyClearTitle => '清除 Stillow 中的全部记录？';

  @override
  String get historyClearBody => '声音陪伴、晨间感受和已同步的健康记录都会从这台设备中移除。收藏和个性化偏好不会受影响。';

  @override
  String get historyTitle => '最近的夜晚';

  @override
  String get historyIntro => '只帮助你回顾，不给睡眠打分。记录最多保留 30 天。';

  @override
  String get localHistoryTitle => 'Stillow 本地记录';

  @override
  String get historyEmpty => '还没有本地记录。播放一段声音，或在醒来后选一下感受，这里才会慢慢出现内容。';

  @override
  String healthLastUpdated(String date) {
    return '上次更新：$date';
  }

  @override
  String get healthOptional => '由你决定是否连接，不会在首次启动时询问。';

  @override
  String get healthInstallRequired => '需要先安装或更新 Health Connect。';

  @override
  String get healthUnavailable => '这台设备暂时不支持系统睡眠数据。';

  @override
  String get healthCardTitle => '手表与系统睡眠记录';

  @override
  String get healthConnectSync => '连接并同步';

  @override
  String get healthUpdate => '更新最近记录';

  @override
  String get healthInstall => '安装或更新 Health Connect';

  @override
  String get healthDisconnectCache => '断开并清除健康缓存';

  @override
  String get healthTrendTitle => '睡眠记录时段走势';

  @override
  String get healthTrendBody => '连接线表示设备记录的起止跨度，不是睡眠质量分数。';

  @override
  String get healthDeviceRecords => '设备记录';

  @override
  String get healthStagesAvailable => '设备同时提供了睡眠阶段';

  @override
  String get healthTimelineSemantics => '设备提供的睡眠阶段时间条，仅供回顾，不是睡眠评分';

  @override
  String get healthTimelineLegend => '浅睡 · 深睡 · REM · 清醒（按设备记录展示）';

  @override
  String historyMorningFeeling(String feeling) {
    return '醒来时：$feeling';
  }

  @override
  String get historyNightSession => '夜醒陪伴';

  @override
  String get historyBedtimeSession => '睡前陪伴';

  @override
  String historySessionLine(String context, String duration) {
    return '$context · $duration';
  }

  @override
  String get historyRemoveNightTooltip => '移除这晚的本地记录';

  @override
  String durationMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String durationHours(int hours) {
    return '$hours 小时';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours 小时 $minutes 分钟';
  }

  @override
  String get healthSyncUnavailable => '这台设备暂时不能读取系统睡眠记录。';

  @override
  String get healthSyncPermissionDeclined => '没有取得读取权限。以后想连接时，再从这里开始就好。';

  @override
  String get healthSyncNoData => '近 30 天没有读到睡眠记录，也可能是系统没有开放读取。';

  @override
  String get healthSyncSuccess => '已更新这台设备中的最近记录。';

  @override
  String get healthSyncFailedUnlocked => '这次没有同步好。设备解锁后再试也可以。';

  @override
  String get healthSyncFailed => '这次没有同步好，稍后再试也可以。';

  @override
  String get userSoundsTitle => '我的声音';

  @override
  String get cancel => '取消';

  @override
  String get userSoundsSubtitle => '列表里的会按顺序播放。不想听了，从列表拿掉就行。';

  @override
  String userSoundsUsage(int count, String used) {
    return '$count/20 个 · 已用 $used MB';
  }

  @override
  String get userSoundsHomeTitle => '我的声音';

  @override
  String get userSoundsHomeSubtitle => '加入的会按列表播放；不想听了就拿掉。';

  @override
  String get userSoundsEmptyTitle => '这里还没有声音';

  @override
  String get userSoundsEmptyBody =>
      '可以一次加入多条熟悉的音乐、课程或朗读。只记下路径，按列表播放；不想听了从列表拿掉即可。';

  @override
  String get userSoundsAdd => '添加声音';

  @override
  String get userSoundsPlayList => '按列表播放';

  @override
  String get userSoundsPrevious => '上一首';

  @override
  String get userSoundsNext => '下一首';

  @override
  String userSoundsPlaylistPosition(int current, int total) {
    return '$current / $total';
  }

  @override
  String get userSoundsImportTitle => '添加本机音频';

  @override
  String get userSoundsImportNotice =>
      '请选择你有权使用的 MP3 或 M4A 文件，可以一次选多个。Stillow 只保存路径，按加入顺序排成列表，不会复制或上传。不想听了从列表拿掉即可，不会删掉手机里原来的文件。最多保留 20 个。';

  @override
  String get userSoundsChooseFile => '选择文件';

  @override
  String get userSoundsImporting => '正在添加…';

  @override
  String get userSoundsCancelImport => '取消添加';

  @override
  String get userSoundsImportCancelled => '已取消添加。';

  @override
  String get userSoundsUnsupported => '目前只支持 MP3 和 M4A 文件。';

  @override
  String get userSoundsEmptyFile => '这个文件没有可播放的内容。';

  @override
  String get userSoundsLibraryFull => '最多可以保留 20 个声音。';

  @override
  String get userSoundsSourceUnavailable => '没有读到这个文件，请重新选择。';

  @override
  String get userSoundsImportInProgress => '另一个声音正在添加。';

  @override
  String get userSoundsWriteFailed => '这次没有保存好，请检查本机空间后重试。';

  @override
  String get userSoundsEdit => '声音设置';

  @override
  String get userSoundsRename => '名称';

  @override
  String get userSoundsLoop => '循环播放';

  @override
  String get userSoundsLoopBody => '适合纯音乐或环境声。';

  @override
  String get userSoundsAttenuate => '每轮逐渐变轻';

  @override
  String get userSoundsAttenuateBody => '循环越久，音量会缓慢降低。';

  @override
  String get userSoundsDefaultTimer => '默认淡出时间';

  @override
  String get userSoundsNoDefaultTimer => '不自动停止';

  @override
  String get userSoundsSave => '保存设置';

  @override
  String get userSoundsDelete => '从列表拿掉';

  @override
  String get userSoundsDeleteTitle => '从播放列表拿掉？';

  @override
  String get userSoundsDeleteBody => '拿掉后不再播放。手机里原来的文件还在。';

  @override
  String get userSoundsRemoveFromList => '从列表拿掉';

  @override
  String get userSoundLocalBadge => '我的声音 · 仅保存在本机';

  @override
  String get userSoundLocalSubtitle => '来自你的本机音频';

  @override
  String get userSoundLocalShortLabel => '我的声音';

  @override
  String get userSoundLocalCreator => '本机文件';

  @override
  String get userSoundsSaved => '设置已保存。';

  @override
  String get userSoundsOperationFailed => '这次操作没有完成，请稍后重试。';

  @override
  String get nightPresetPersonalTitle => '我的声音';

  @override
  String get nightPresetBuiltInTitle => 'Stillow 声音';
}
