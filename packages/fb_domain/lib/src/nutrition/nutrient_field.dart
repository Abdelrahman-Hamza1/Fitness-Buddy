import 'package:fb_domain/src/nutrition/nutrients.dart';

/// Editable nutrient fields (AI-072). kcal has its own energy unit.
enum NutrientField {
  /// Energy.
  kcal('kcal'),

  /// Protein.
  protein('g'),

  /// Carbohydrate.
  carbs('g'),

  /// Fat.
  fat('g'),

  /// Fiber.
  fiber('g'),

  /// Sugar.
  sugar('g', NutrientKey.sugar),

  /// Saturated fat.
  saturatedFat('g', NutrientKey.saturatedFat),

  /// Trans fat.
  transFat('g', NutrientKey.transFat),

  /// Sodium.
  sodium('mg', NutrientKey.sodium),

  /// Cholesterol.
  cholesterol('mg', NutrientKey.cholesterol),

  /// Alcohol.
  alcohol('g', NutrientKey.alcohol);

  new(this.unit, [this.extraKey]);

  /// Stable unit code.
  final String unit;

  /// Absolute meal-input cap: 20,000 kcal or 5,000 g.
  /// Sodium/cholesterol allow up to 50,000 mg (50 g) per meal; these
  /// generous input limits reject accidents, not unusual nutrition.
  double get maxValue => switch (unit) {
    'kcal' => 20000,
    'mg' => 50000,
    _ => 5000,
  };

  /// Optional-nutrient key; core fields have none.
  final NutrientKey? extraKey;
}

/// Named access shared by overrides and the editing sheet.
extension NutrientValues on Nutrients {
  /// Missing extras remain unknown.
  double? valueOf(NutrientField field) => switch (field) {
    NutrientField.kcal => kcal,
    NutrientField.protein => protein,
    NutrientField.carbs => carbs,
    NutrientField.fat => fat,
    NutrientField.fiber => fiber,
    _ => extras[field.extraKey],
  };
}

/// Absolute input becomes per-100 values; no energy inference (AI-072).
abstract final class NutrientOverride {
  /// Preserves every field not explicitly supplied. Values are user content.
  static Nutrients apply(
    Nutrients per100, {
    required double amount,
    required Map<NutrientField, double> values,
  }) {
    if (!amount.isFinite || amount <= 0) throw ArgumentError('invalid amount');
    checkValues(values);
    double derived(double value) {
      final result = value == 0 ? 0.0 : value * 100 / amount;
      // sync-entities.json caps every stored nutrient at 1e12.
      if (!result.isFinite || result > 1e12) {
        throw ArgumentError('override per100 out of range');
      }
      return result;
    }

    double field(NutrientField f) =>
        values.containsKey(f) ? derived(values[f]!) : per100.valueOf(f)!;
    return Nutrients(
      kcal: field(NutrientField.kcal),
      protein: field(NutrientField.protein),
      carbs: field(NutrientField.carbs),
      fat: field(NutrientField.fat),
      fiber: field(NutrientField.fiber),
      extras: {
        ...per100.extras,
        for (final MapEntry(:key, :value) in values.entries)
          ?key.extraKey: derived(value),
      },
    );
  }

  /// Validates without including the input values in an exception.
  static void checkValues(Map<NutrientField, double> values) {
    if (values.isEmpty ||
        values.entries.any(
          (e) => !e.value.isFinite || e.value < 0 || e.value > e.key.maxValue,
        )) {
      throw ArgumentError('override needs finite nonnegative values');
    }
  }
}
