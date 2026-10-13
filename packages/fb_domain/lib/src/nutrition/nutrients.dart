import 'package:fb_domain/src/math/rounding.dart';

/// The unit of a nutrient value.
enum NutrientUnit {
  /// Grams.
  gram('g'),

  /// Milligrams.
  milligram('mg');

  new(this.code);

  /// The stable unit code.
  final String code;
}

/// Optional nutrients, stored when the data has them (FD-002, D-019). Each
/// key has a fixed unit.
enum NutrientKey {
  /// Sugars, g.
  sugar('sugar', NutrientUnit.gram),

  /// Saturated fat, g.
  saturatedFat('saturated_fat', NutrientUnit.gram),

  /// Trans fat, g.
  transFat('trans_fat', NutrientUnit.gram),

  /// Sodium, mg.
  sodium('sodium', NutrientUnit.milligram),

  /// Cholesterol, mg.
  cholesterol('cholesterol', NutrientUnit.milligram),

  /// Alcohol, g (counted at 7 kcal/g by the sanity check).
  alcohol('alcohol', NutrientUnit.gram);

  new(this.code, this.unit);

  /// The stable code used in stored data and the catalog.
  final String code;

  /// The unit values of this nutrient are in.
  final NutrientUnit unit;

  /// The key whose [code] is exactly [code], or `null`.
  static NutrientKey? fromCode(String code) {
    for (final key in values) {
      if (key.code == code) return key;
    }
    return null;
  }
}

/// Nutrient values: per 100 g/ml on a food, or a snapshot on a logged entry.
///
/// Implements FD-002: the core five (kcal, protein, carbs, fat, fiber) are
/// always present and never negative. Extras are optional and kept apart from
/// the core. A missing extra is unknown, not zero: scaling keeps extras as
/// they are, and adding keeps an extra only when both sides have it, so a
/// partial sum never pretends to be complete (S08 D16).
///
/// Carbs are total carbohydrate as the source states it (US labels include
/// fiber, EU labels don't). The sanity check accepts both.
final class Nutrients {
  /// Nutrient values. Every value must be finite and not negative.
  new({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    Map<NutrientKey, double> extras = const {},
  }) : extras = Map.unmodifiable(extras) {
    _check(kcal, 'kcal');
    _check(protein, 'protein');
    _check(carbs, 'carbs');
    _check(fat, 'fat');
    _check(fiber, 'fiber');
    for (final MapEntry(:key, :value) in extras.entries) {
      _check(value, key.code);
    }
  }

  /// All core values zero, no extras.
  static final Nutrients zero = Nutrients(
    kcal: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
  );

  /// Energy, kcal.
  final double kcal;

  /// Protein, g.
  final double protein;

  /// Carbohydrate, g.
  final double carbs;

  /// Fat, g.
  final double fat;

  /// Fiber, g.
  final double fiber;

  /// Optional nutrients the data has, each in its key's unit.
  final Map<NutrientKey, double> extras;

  /// The value of [key], or `null` when it is unknown.
  double? extra(NutrientKey key) => extras[key];

  /// Every value multiplied by [factor] (finite, not negative).
  Nutrients scale(double factor) {
    if (!factor.isFinite || factor < 0) {
      throw ArgumentError.value(factor, 'factor', 'must be finite and >= 0');
    }
    return _map((value) => value * factor);
  }

  /// The sum of this and [other]. An extra is kept only if both have it.
  Nutrients operator +(Nutrients other) => Nutrients(
    kcal: kcal + other.kcal,
    protein: protein + other.protein,
    carbs: carbs + other.carbs,
    fat: fat + other.fat,
    fiber: fiber + other.fiber,
    extras: {
      for (final MapEntry(:key, :value) in extras.entries)
        if (other.extras[key] case final otherValue?) key: value + otherValue,
    },
  );

  /// Every value rounded to storage precision (S08 D2), for a snapshot.
  Nutrients rounded() => _map(StoragePrecision.round);

  /// The sum of [all], or [zero] when it is empty. Extras follow `+`.
  static Nutrients sum(Iterable<Nutrients> all) =>
      all.isEmpty ? zero : all.reduce((a, b) => a + b);

  Nutrients _map(double Function(double) f) => Nutrients(
    kcal: f(kcal),
    protein: f(protein),
    carbs: f(carbs),
    fat: f(fat),
    fiber: f(fiber),
    extras: extras.map((key, value) => MapEntry(key, f(value))),
  );

  @override
  bool operator ==(Object other) =>
      other is Nutrients &&
      other.kcal == kcal &&
      other.protein == protein &&
      other.carbs == carbs &&
      other.fat == fat &&
      other.fiber == fiber &&
      other.extras.length == extras.length &&
      extras.entries.every((e) => other.extras[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    kcal,
    protein,
    carbs,
    fat,
    fiber,
    Object.hashAllUnordered(
      extras.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'Nutrients(kcal: $kcal, protein: $protein, carbs: $carbs, fat: $fat, '
      'fiber: $fiber, extras: $extras)';
}

void _check(double value, String name) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(value, name, 'must be finite and >= 0');
  }
}
