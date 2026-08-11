import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/app.dart';
import 'package:stillow/data/content_catalog.dart';
import 'package:stillow/data/preference_store.dart';
import 'package:stillow/domain/stillow_models.dart';
import 'package:stillow/features/morning/morning_review_screen.dart';
import 'package:stillow/theme/stillow_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentCatalog catalog;

  setUpAll(() async {
    catalog = await ContentCatalog.loadAsset();
  });

  testWidgets('新用户可以轻松完成三步首次选择', (tester) async {
    final store = MemoryPreferenceStore();

    await tester.pumpWidget(
      StillowApp(
        initialProfile: const UserProfile(),
        preferenceStore: store,
        catalog: catalog,
        region: ContentRegion.mainlandChina,
      ),
    );

    expect(find.text('今晚，你更希望得到哪种陪伴？'), findsOneWidget);
    expect(find.text('先随便听听'), findsOneWidget);

    await tester.tap(find.text('让脑袋慢慢安静'));
    await tester.pump();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('轻轻说话，或不必听懂的课程'));
    await tester.pump();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('偶尔提醒一下就好'));
    await tester.pump();
    await tester.tap(find.text('今晚先试试'));
    await tester.pumpAndSettle();

    expect(find.text('今晚不用完成\n任何任务。'), findsOneWidget);
    expect(store.profile.onboardingComplete, isTrue);
    expect(store.profile.supportNeed, SupportNeed.quietMind);
  });

  testWidgets('已完成首次选择的用户直接看到低压力首页', (tester) async {
    final profile = const UserProfile(
      onboardingComplete: true,
      supportNeed: SupportNeed.relaxBody,
      soundPreference: SoundPreference.softVoice,
      guidancePreference: GuidancePreference.stepByStep,
    );

    await tester.pumpWidget(
      StillowApp(
        initialProfile: profile,
        preferenceStore: MemoryPreferenceStore(profile),
        catalog: catalog,
        region: ContentRegion.mainlandChina,
      ),
    );

    expect(find.text('今晚先试试'), findsOneWidget);
    expect(find.text('午夜海浪'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('夜里醒来时'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('夜里醒来时'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('醒来以后'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('听一段不必学会的课'), findsOneWidget);
    expect(find.text('醒来以后'), findsOneWidget);
    expect(find.text('睡眠分数'), findsNothing);
  });

  testWidgets('晨间回顾不打分，梦境解析显示娱乐边界', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: StillowTheme.dark, home: const MorningReviewScreen()),
    );

    await tester.tap(find.text('还是有点累'));
    await tester.pump();
    expect(find.text('昨晚似乎没有休息得很舒服。'), findsOneWidget);
    expect(find.textContaining('不是睡眠分数'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('看看我的梦'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pump();
    await tester.tap(find.text('看看我的梦'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '我在陌生的房子里看着窗外下雨');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('看看这个梦'));
    await tester.tap(find.text('看看这个梦'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('空间与内心角落'), findsOneWidget);
    expect(find.textContaining('仅供休闲娱乐'), findsOneWidget);
    expect(find.textContaining('退出后不保存'), findsOneWidget);
  });
}
