import 'package:flutter_test/flutter_test.dart';
import 'package:stillow/domain/sleep_support_review.dart';

void main() {
  test('持续频繁且影响白天的模式会温和建议专业支持', () {
    final result = evaluateSleepSupportReview(
      const SleepSupportReviewAnswers(
        duration: SleepDifficultyDuration.threeMonthsOrMore,
        frequency: SleepDifficultyFrequency.threeOrMoreNights,
        daytimeImpact: DaytimeImpact.noticeable,
        sleepOpportunity: SleepOpportunity.usuallyEnough,
      ),
    );

    expect(result, SleepSupportGuidance.considerProfessionalSupport);
  });

  test('只有持续时间较长时不会自行贴上慢性失眠标签', () {
    final result = evaluateSleepSupportReview(
      const SleepSupportReviewAnswers(
        duration: SleepDifficultyDuration.threeMonthsOrMore,
        frequency: SleepDifficultyFrequency.oneOrTwoNights,
        daytimeImpact: DaytimeImpact.little,
        sleepOpportunity: SleepOpportunity.usuallyEnough,
      ),
    );

    expect(result, SleepSupportGuidance.keepObserving);
  });

  test('白天功能或安全已明显受影响时立即建议专业支持', () {
    final result = evaluateSleepSupportReview(
      const SleepSupportReviewAnswers(
        duration: SleepDifficultyDuration.underOneMonth,
        frequency: SleepDifficultyFrequency.oneOrTwoNights,
        daytimeImpact: DaytimeImpact.clearOrUnsafe,
        sleepOpportunity: SleepOpportunity.varies,
      ),
    );

    expect(result, SleepSupportGuidance.considerProfessionalSupport);
  });

  test('全部跳过时只给通用说明', () {
    expect(
      evaluateSleepSupportReview(const SleepSupportReviewAnswers()),
      SleepSupportGuidance.keepObserving,
    );
  });
}
