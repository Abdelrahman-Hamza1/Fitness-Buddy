import 'dart:math' as math;

import 'package:fb_domain/src/targets/target_profile.dart';

/// An explicit macro override, in grams or percent of base calorie energy.
final class MacroOverride {
  /// Fixed base-day grams (zero is permitted).
  new grams(double grams) : value = grams, isPercent = false {
    checkTargetNumber(grams, allowZero: true);
  }

  /// Base-day energy percentage, from 0 to 100.
  new percent(double percent) : value = percent, isPercent = true {
    if (!percent.isFinite || percent < 0 || percent > 100) {
      throw ArgumentError('macro percentage must be between zero and 100');
    }
  }

  /// Input quantity in the chosen unit.
  final double value;

  /// Whether [value] is a base-energy percentage instead of grams.
  final bool isPercent;

  /// Resolve grams once against base calories, not each shifted day's calories.
  double gramsAt(double baseKcal, double kcalPerGram) {
    checkTargetNumber(baseKcal);
    checkTargetNumber(kcalPerGram);
    final grams = isPercent ? baseKcal * value / 100 / kcalPerGram : value;
    if (!grams.isFinite) throw ArgumentError('macro conversion overflow');
    return grams;
  }
}

/// User macro preferences; no target values are persisted by this model.
final class MacroSettings {
  /// Fiber uses grams, since a fiber energy percentage is not defined.
  new({
    this.protein,
    this.fat,
    this.carbs,
    this.fiberGrams,
    this.caloriesProteinOnly = false,
  }) {
    if (fiberGrams case final fiber?) {
      checkTargetNumber(fiber, allowZero: true);
    }
  }

  /// Default is 1.8 g/kg goal/current weight.
  final MacroOverride? protein;

  /// Default 30% of base energy; the g/kg minimum still applies.
  final MacroOverride? fat;

  /// Default is remaining energy; explicit base grams flex by calorie delta/4.
  final MacroOverride? carbs;

  /// Optional fixed daily fiber; otherwise 14 g per 1,000 base kcal.
  final double? fiberGrams;

  /// Fat and carbs have no targets in this mode (TG-054).
  final bool caloriesProteinOnly;
}

/// Resolves daily P/F/fiber once; only carbohydrates flex (TG-050–055).
final class MacroPlan {
  /// [weightKg] is goal weight if available, current weight otherwise.
  factory calculate({
    required double baseKcal,
    required double weightKg,
    MacroSettings? settings,
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    checkTargetNumber(baseKcal);
    checkTargetNumber(weightKg);
    final input = settings ?? MacroSettings();
    final protein =
        input.protein?.gramsAt(baseKcal, 4) ?? defaults.proteinPerKg * weightKg;
    final fat = input.caloriesProteinOnly
        ? null
        : math.max(
            input.fat?.gramsAt(baseKcal, 9) ??
                baseKcal * defaults.fatFraction / 9,
            weightKg * defaults.fatPerKgFloor,
          );
    return MacroPlan._(
      baseKcal,
      protein,
      fat,
      input.fiberGrams ?? baseKcal / 1000 * defaults.fiberPer1000Kcal,
      input.caloriesProteinOnly ? null : input.carbs?.gramsAt(baseKcal, 4),
    );
  }

  const new _(
    this.baseKcal,
    this.proteinGrams,
    this.fatGrams,
    this.fiberGrams,
    this.baseCarbOverrideGrams,
  );

  /// Base energy used to resolve percentages and fiber.
  final double baseKcal;

  /// Fixed daily protein target.
  final double proteinGrams;

  /// Fixed daily fat target, absent in protein-only mode.
  final double? fatGrams;

  /// Fixed daily fiber target.
  final double fiberGrams;

  /// Explicit base carb grams, when overridden.
  final double? baseCarbOverrideGrams;

  /// Unrounded daily targets and any energy mismatch. Fixed P/F are never
  /// silently reduced to fit a low shifted day or conflicting user overrides.
  DailyMacros forDay(double kcal) {
    checkTargetNumber(kcal);
    if (fatGrams == null) {
      return DailyMacros._(
        kcal,
        proteinGrams,
        null,
        null,
        fiberGrams,
        math.max(0, proteinGrams * 4 - kcal),
        null,
      );
    }
    final fixedEnergy = proteinGrams * 4 + fatGrams! * 9;
    final carbs = math.max<double>(
      0,
      baseCarbOverrideGrams == null
          ? (kcal - fixedEnergy) / 4
          : baseCarbOverrideGrams! + (kcal - baseKcal) / 4,
    );
    final difference = fixedEnergy + carbs * 4 - kcal;
    return DailyMacros._(
      kcal,
      proteinGrams,
      fatGrams,
      carbs,
      fiberGrams,
      math.max(0, difference),
      difference,
    );
  }
}

/// Numeric daily targets; presentation supplies localized explanation strings.
final class DailyMacros {
  const new _(
    this.kcal,
    this.proteinGrams,
    this.fatGrams,
    this.carbsGrams,
    this.fiberGrams,
    this.energyDeficitKcal,
    this.energyDifferenceKcal,
  );

  /// Day's calorie target.
  final double kcal;

  /// Fixed protein target.
  final double proteinGrams;

  /// Fixed fat target, absent in calories/protein mode.
  final double? fatGrams;

  /// Flexible carbohydrate target, absent in calories/protein mode.
  final double? carbsGrams;

  /// Fixed fiber target.
  final double fiberGrams;

  /// Energy above the day's calories needed for targets. In protein-only mode,
  /// this counts only protein energy, since fat/carbs have no targets.
  final double energyDeficitKcal;

  /// Macro energy minus calories; negative means explicit overrides leave
  /// energy unassigned. Null in protein-only mode, where totals aren't defined.
  final double? energyDifferenceKcal;
}
