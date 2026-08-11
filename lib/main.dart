import 'package:flutter/widgets.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'data/content_catalog.dart';
import 'data/preference_store.dart';
import 'data/sleep_history_store.dart';
import 'services/sleep_health_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.stillow.audio',
    androidNotificationChannelName: 'Stillow 夜间陪伴',
    androidNotificationOngoing: true,
  );

  final store = LocalPreferenceStore();
  final profile = await store.load();
  final catalog = await ContentCatalog.loadAsset();
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final region = ContentRegionResolver.fromCountryCode(locale.countryCode);

  runApp(
    StillowApp(
      initialProfile: profile,
      preferenceStore: store,
      catalog: catalog,
      region: region,
      sleepHistoryStore: LocalSleepHistoryStore(),
      sleepHealthGateway: PluginSleepHealthGateway(),
    ),
  );
}
