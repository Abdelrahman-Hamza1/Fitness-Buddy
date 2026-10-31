import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';

/// Search row with calculated preview and structured navigation identity.
final class FoodSearchRow {
  /// Creates this structured value.
  new({
    required this.choice,
    required this.tier,
    ParsedAmount? parsed,
    UnitSystem system = UnitSystem.metric,
    this.matchedKey,
    this.matchedDisplay = false,
  }) : defaultPortion = choice.defaultPortion(parsed: parsed, system: system);

  /// Food and units used by the preview and sheet.
  final FoodChoice choice;

  /// Ranking tier before de-duplication.
  final SourceTier tier;

  /// The normalized name the query matched (D-091), or null (recents, a
  /// match through the history). The row shows "Matched …" when it is an
  /// alias or the other language's name (see `FoodResultRow`).
  final String? matchedKey;

  /// Whether [matchedKey] is a display name (of the food or its dish)
  /// rather than an alias.
  final bool matchedDisplay;

  /// FD-022 input: resolvable last use, parsed quantity or default.
  final Quantity defaultPortion;

  /// Stable source-kind and food-ID identity.
  String get identity => '${choice.ref.kind.code}:${choice.ref.id}';

  /// English display name.
  String get nameEn => choice.names.en;

  /// Optional Arabic display name.
  String? get nameAr => choice.names.ar;

  /// Provenance badge for this food.
  FoodSource get source => choice.badge;

  /// Structured identity passed to the amount sheet.
  FoodChoiceRef get choiceRef => FoodChoiceRef(choice.ref);

  /// Locally calculated kcal for the default input.
  double get kcalForDefault => switch (const NutritionCalculator().compute(
    per100: choice.per100,
    measures: choice.measures,
    input: defaultPortion,
  )) {
    Computed(:final snapshot) => snapshot.nutrients.kcal,
    NotComputed() => 0,
  };
}
