import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/food_ref.dart';
import 'package:fb_domain/src/diary/provenance.dart';
import 'package:fb_domain/src/nutrition/nutrient_field.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// Why a typed estimate can't be logged (A62 D7).
enum UserEstimateProblem {
  /// kcal is missing, not finite or outside 1–[UserEstimate.maxKcal].
  kcal,

  /// A given macro is not finite or outside 0–[UserEstimate.maxMacroGrams].
  macro,
}

/// A meal estimate the user typed (DY-005, A62 D2, D3, D7): one kcal number,
/// an optional name and optional protein, carbs and fat. It is a total, not
/// a food: no sanity check (FD-012) ever runs on it. The app never invents
/// a value: what isn't typed stays unknown (stored as 0, W3).
///
/// Content-free [toString].
final class UserEstimate {
  /// The estimate as typed. Validate with [check] first; [food] throws an
  /// `ArgumentError` (without values) for one that doesn't pass.
  const new({
    required this.kcal,
    this.name,
    this.protein,
    this.carbs,
    this.fat,
  });

  /// The estimate an entry holds, or null when [food] isn't a user
  /// estimate. Used to prefill Edit.
  static UserEstimate? of(EntryFood food) {
    if (!food.userEstimate) return null;
    double? macro(NutrientField f) =>
        food.known.contains(f) ? food.per100.valueOf(f) : null;
    final name = food.names.en;
    return UserEstimate(
      kcal: food.per100.kcal,
      name: name == unnamedName ? null : name,
      protein: macro(NutrientField.protein),
      carbs: macro(NutrientField.carbs),
      fat: macro(NutrientField.fat),
    );
  }

  /// The largest meal estimate, kcal.
  static const double maxKcal = 10000;

  /// The largest given macro, g.
  static const double maxMacroGrams = 1000;

  /// The stored name of an unnamed estimate; the UI shows its own label.
  static const String unnamedName = 'Estimate';

  /// The longest name kept, in characters.
  static const int maxNameLength = 80;

  /// The amount an estimate is logged at: 100 g, typed as 1 serving, so
  /// the snapshot equals the per-100 values (FD-073).
  static EntryAmount get amount => EntryAmount(
    input: Quantity(1, 'serving'),
    amount: 100,
    basis: NutrientBasis.per100g,
  );

  /// Calories.
  final double kcal;

  /// The name, or null for an unnamed estimate. User content.
  final String? name;

  /// Protein, g; null when not given.
  final double? protein;

  /// Carbs, g; null when not given.
  final double? carbs;

  /// Fat, g; null when not given.
  final double? fat;

  /// The first problem, or null when it can be logged.
  UserEstimateProblem? check() {
    if (!kcal.isFinite || kcal < 1 || kcal > maxKcal) {
      return UserEstimateProblem.kcal;
    }
    for (final value in [protein, carbs, fat]) {
      if (value == null) continue;
      if (!value.isFinite || value < 0 || value > maxMacroGrams) {
        return UserEstimateProblem.macro;
      }
    }
    return null;
  }

  /// The entry food: `estimate` reference, `yours` source, an estimate,
  /// edited by the user; protein/carbs/fat known exactly when typed (an
  /// explicit 0 is known), fiber never asked so unknown.
  EntryFood food() {
    if (check() != null) throw ArgumentError('estimate out of range');
    final trimmed = name?.trim();
    final shown = trimmed == null || trimmed.isEmpty
        ? unnamedName
        : (trimmed.length > maxNameLength
              ? trimmed.substring(0, maxNameLength)
              : trimmed);
    return EntryFood(
      ref: FoodRef.estimate(),
      names: FoodNames(shown),
      per100: Nutrients(
        kcal: kcal,
        protein: protein ?? 0,
        carbs: carbs ?? 0,
        fat: fat ?? 0,
        fiber: 0,
      ),
      provenance: Provenance(source: FoodSource.yours, isEstimate: true),
      editedByUser: true,
      userEstimate: true,
      known: {
        if (protein != null) NutrientField.protein,
        if (carbs != null) NutrientField.carbs,
        if (fat != null) NutrientField.fat,
      },
    );
  }

  /// The food for editing [current], a user estimate (A62 D11, review
  /// fix): kcal, name, protein, carbs and fat from this estimate; fiber
  /// and its known state, the extras and the provenance kept from
  /// [current], since the editor doesn't show them (an AI-072 override can
  /// have set them). Any other food: [food].
  EntryFood foodReplacing(EntryFood current) {
    final typed = food();
    if (!current.userEstimate) return typed;
    final fiberKnown = current.known.contains(NutrientField.fiber);
    final kept = current.per100;
    return EntryFood(
      ref: typed.ref,
      names: typed.names,
      per100: Nutrients(
        kcal: typed.per100.kcal,
        protein: typed.per100.protein,
        carbs: typed.per100.carbs,
        fat: typed.per100.fat,
        fiber: fiberKnown ? kept.fiber : 0,
        extras: kept.extras,
      ),
      provenance: current.provenance,
      editedByUser: true,
      userEstimate: true,
      known: {...typed.known, if (fiberKnown) NutrientField.fiber},
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserEstimate &&
      other.kcal == kcal &&
      other.name == name &&
      other.protein == protein &&
      other.carbs == carbs &&
      other.fat == fat;

  @override
  int get hashCode => Object.hash(kcal, name, protein, carbs, fat);

  /// No values or name.
  @override
  String toString() => 'UserEstimate';
}
