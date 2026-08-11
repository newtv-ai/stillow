enum SleepDifficultyDuration {
  underOneMonth,
  oneToThreeMonths,
  threeMonthsOrMore,
  unsure,
}

enum SleepDifficultyFrequency {
  lessThanWeekly,
  oneOrTwoNights,
  threeOrMoreNights,
  unsure,
}

enum DaytimeImpact { little, noticeable, clearOrUnsafe, unsure }

enum SleepOpportunity { usuallyEnough, varies, usuallyNotEnough, unsure }

enum SleepSupportGuidance { keepObserving, considerProfessionalSupport }

class SleepSupportReviewAnswers {
  const SleepSupportReviewAnswers({
    this.duration = SleepDifficultyDuration.unsure,
    this.frequency = SleepDifficultyFrequency.unsure,
    this.daytimeImpact = DaytimeImpact.unsure,
    this.sleepOpportunity = SleepOpportunity.unsure,
  });

  final SleepDifficultyDuration duration;
  final SleepDifficultyFrequency frequency;
  final DaytimeImpact daytimeImpact;
  final SleepOpportunity sleepOpportunity;
}

SleepSupportGuidance evaluateSleepSupportReview(
  SleepSupportReviewAnswers answers,
) {
  if (answers.daytimeImpact == DaytimeImpact.clearOrUnsafe) {
    return SleepSupportGuidance.considerProfessionalSupport;
  }

  final hasPersistentPattern =
      answers.duration == SleepDifficultyDuration.threeMonthsOrMore &&
      answers.frequency == SleepDifficultyFrequency.threeOrMoreNights &&
      answers.daytimeImpact == DaytimeImpact.noticeable;
  final hasReasonableOpportunity =
      answers.sleepOpportunity != SleepOpportunity.usuallyNotEnough;

  return hasPersistentPattern && hasReasonableOpportunity
      ? SleepSupportGuidance.considerProfessionalSupport
      : SleepSupportGuidance.keepObserving;
}
