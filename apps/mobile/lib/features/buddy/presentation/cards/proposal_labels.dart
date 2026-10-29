import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/amount_text.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';

// The words of a food proposal card (A22 D13): typed card values in, ARB
// text out. Never the model's own words (AI-143).

/// Calories as the app shows them: "1,430".
String kcalText(AppLocalizations l10n, double kcal) =>
    l10n.diaryBigKcal(DisplayRounding.kcal(kcal));

/// Calories, with `~` when [approx] (an estimate).
String _kcal(AppLocalizations l10n, double kcal, {required bool approx}) =>
    approx ? l10n.proposalApprox(kcalText(l10n, kcal)) : kcalText(l10n, kcal);

/// The word for a food state ("Cooked").
String foodStateLabel(AppLocalizations l10n, FoodState state) =>
    switch (state) {
      FoodState.raw => l10n.proposalStateRaw,
      FoodState.cooked => l10n.proposalStateCooked,
      FoodState.dry => l10n.proposalStateDry,
      FoodState.drained => l10n.proposalStateDrained,
      FoodState.fried => l10n.proposalStateFried,
      FoodState.asSold => l10n.proposalStateAsSold,
    };

/// The label of [option] of [dimension]: an answer chip or assumption chip.
String optionLabel(
  AppLocalizations l10n,
  ProposalDimension dimension,
  ProposalOption option, {
  required UnitSystem system,
}) {
  String amountText(Quantity q) =>
      servingText(l10n, input: q, basis: NutrientBasis.per100g, system: system);
  return switch (option.effect) {
    ProposalFoodEffect(:final food) => switch (dimension.kind) {
      ProposalDimensionKind.state => foodStateLabel(l10n, food.state),
      _ => food.names.en,
    },
    ProposalQuantityEffect(quantity: final q) => amountText(q),
    ProposalComponentEffect(:final quantity) =>
      quantity == null || quantity.amount <= 0
          ? l10n.proposalOilNone
          : l10n.proposalOilAmount(amountText(quantity)),
    ProposalRetentionEffect(:final fraction) =>
      fraction >= 1 ? l10n.proposalOilAll : l10n.proposalOilMost,
    ProposalShareEffect(:final fraction) => l10n.proposalShareOption(
      (fraction * 100).round(),
    ),
  };
}

/// [name] for use inside a sentence: its first letter in lower case
/// ("rice, white, cooked").
String inlineFoodName(String name) => name.isEmpty
    ? name
    : name.substring(0, 1).toLowerCase() + name.substring(1);

/// An assumption chip's text, with the food it's about where the choice
/// alone would be unclear (AI-033): "Rice: cooked", "Chicken: 150 g",
/// "1 tsp of oil", "Most oil eaten", "Your share: 50%".
String chipLabel(
  AppLocalizations l10n,
  FoodChipView chip, {
  required UnitSystem system,
}) {
  final option = chip.selected;
  return switch ((chip.dimension.kind, option.effect)) {
    (ProposalDimensionKind.state, ProposalFoodEffect(:final food)) =>
      l10n.proposalChipFood(chip.foodName, _stateWord(l10n, food.state)),
    (ProposalDimensionKind.portion, _) => l10n.proposalChipFood(
      chip.foodName,
      optionLabel(l10n, chip.dimension, option, system: system),
    ),
    (_, ProposalRetentionEffect(:final fraction)) =>
      fraction >= 1 ? l10n.proposalChipOilAll : l10n.proposalChipOilMost,
    (_, ProposalShareEffect(:final fraction)) => l10n.assumptionShare(
      (fraction * 100).round(),
    ),
    _ => optionLabel(l10n, chip.dimension, option, system: system),
  };
}

String _stateWord(AppLocalizations l10n, FoodState state) => switch (state) {
  FoodState.raw => l10n.assumptionStateRaw,
  FoodState.cooked => l10n.assumptionStateCooked,
  FoodState.dry => l10n.assumptionStateDry,
  FoodState.drained => l10n.assumptionStateDrained,
  FoodState.fried => l10n.assumptionStateFried,
  FoodState.asSold => l10n.assumptionStateAsSold,
};

/// The question about [question]'s dimension (AI-034).
String questionText(AppLocalizations l10n, FoodQuestionView question) {
  final food = inlineFoodName(question.foodName);
  return switch (question.dimension.kind) {
    ProposalDimensionKind.state => l10n.proposalQuestionState(food),
    ProposalDimensionKind.fat => l10n.proposalQuestionFat,
    ProposalDimensionKind.variant => l10n.proposalQuestionVariant,
    ProposalDimensionKind.portion => l10n.proposalQuestionPortion(food),
    ProposalDimensionKind.oilRetention => l10n.proposalQuestionOilRetention,
    ProposalDimensionKind.share => l10n.proposalQuestionShare(food),
  };
}

/// Why Log it is disabled.
String blockedText(AppLocalizations l10n, ProposalIssue issue) =>
    switch (issue) {
      ProposalIssue.needsAmount => l10n.proposalBlockedNeedsAmount,
      ProposalIssue.missingFoodFacts ||
      ProposalIssue.staleFacts ||
      ProposalIssue.factsMismatch => l10n.proposalBlockedMissingFood,
      _ => l10n.proposalBlockedOther,
    };

/// Why a line is an estimate (AI-032).
String estimateReasonText(AppLocalizations l10n, EstimateReason reason) =>
    switch (reason) {
      EstimateReason.referencePortion => l10n.proposalEstimateReasonReference,
      EstimateReason.buddyEstimate => l10n.proposalEstimateReasonBuddy,
      EstimateReason.guessedAmount => l10n.proposalEstimateReasonAmount,
    };

/// "Today after this: 1,240 left" with a target, else "… 1,430 eaten"
/// (AI-031, A22 D15). For another day, [day] names it ("Yesterday after
/// this: …").
String todayAfterText(
  AppLocalizations l10n,
  ProposalDayPreview preview, {
  String? day,
  bool approx = false,
}) {
  String kcalText(AppLocalizations l10n, double kcal) =>
      _kcal(l10n, kcal, approx: approx);
  final left = preview.remainingKcal;
  if (left != null && left < 0) {
    final over = kcalText(l10n, -left);
    return day == null
        ? l10n.proposalTodayAfterOver(over)
        : l10n.proposalDayAfterOver(day, over);
  }
  if (left != null) {
    final shown = kcalText(l10n, left);
    return day == null
        ? l10n.proposalTodayAfter(shown)
        : l10n.proposalDayAfter(day, shown);
  }
  final eaten = kcalText(l10n, preview.eaten?.kcal ?? 0);
  return day == null
      ? l10n.proposalTodayAfterEaten(eaten)
      : l10n.proposalDayAfterEaten(day, eaten);
}

/// "Logged 191 kcal · 1,240 left today" (AI-140; English, AI-143). For
/// another day, [dayInline] names it instead ("Logged 191 kcal for
/// yesterday").
String loggedText(
  AppLocalizations l10n,
  double kcal,
  ProposalDayPreview day, {
  String? dayInline,
  bool approx = false,
}) {
  String kcalText(AppLocalizations l10n, double kcal) =>
      _kcal(l10n, kcal, approx: approx);
  final logged = kcalText(l10n, kcal);
  if (dayInline != null) return l10n.proposalLoggedOnDay(logged, dayInline);
  final left = day.remainingKcal;
  if (left != null && left < 0) {
    return l10n.proposalLoggedOver(logged, kcalText(l10n, -left));
  }
  if (left != null) return l10n.proposalLogged(logged, kcalText(l10n, left));
  return l10n.proposalLoggedEaten(logged, kcalText(l10n, day.eaten?.kcal ?? 0));
}
