import 'package:flutter/widgets.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'data/content_catalog.dart';
import 'data/preference_store.dart';
import 'data/sleep_history_store.dart';
import 'data/user_sound_store.dart';
import 'domain/stillow_models.dart';
import 'services/sleep_health_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LocalPreferenceStore();
  final profile = await store.load();
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final notificationLanguage = switch (profile.appLanguagePreference) {
    AppLanguagePreference.english => 'en',
    AppLanguagePreference.simplifiedChinese => 'zh',
    AppLanguagePreference.system =>
      deviceLocale.languageCode == 'zh' ? 'zh' : 'en',
  };
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.stillow.audio',
    androidNotificationChannelName: notificationLanguage == 'zh'
        ? 'Stillow 夜间陪伴'
        : 'Stillow night audio',
    androidNotificationIcon: 'drawable/ic_stillow_notification',
    androidNotificationOngoing: true,
  );

  final catalog = await ContentCatalog.loadAsset();
  final userSoundStore = LocalUserSoundStore();
  List<UserSound> userSounds;
  try {
    userSounds = await userSoundStore.load();
  } catch (_) {
    userSounds = const [];
  }
  final region = ContentRegionResolver.fromCountryCode(
    deviceLocale.countryCode,
  );

  runApp(
    StillowApp(
      initialProfile: profile,
      preferenceStore: store,
      catalog: catalog,
      region: region,
      sleepHistoryStore: LocalSleepHistoryStore(),
      sleepHealthGateway: PluginSleepHealthGateway(),
      initialUserSounds: userSounds,
      userSoundStore: userSoundStore,
    ),
  );
}
