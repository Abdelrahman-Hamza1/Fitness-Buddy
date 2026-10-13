import 'dart:math' as math;

import 'package:fb_domain/src/nutrition/nutrients.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// The thresholds of the FD-012 sanity check (S08 D5, A4). One value, so the
/// catalog build (S13) can tune them without touching the rule.
final class SanityTolerance {
  /// Thresholds; the defaults are the documented ones (README "Sanity
  /// tolerances").
  const new({
    this.okKcal = 15,
    this.okFraction = 0.15,
    this.warnKcal = 30,
    this.warnFraction = 0.30,
    this.maxKcalPer100 = 920,
    this.maxMacroGramsPer100g = 105,
  });

  /// The default thresholds.
  static const SanityTolerance defaults = SanityTolerance();

  /// Absolute deviation (kcal) that is always ok, for low-kcal foods.
  final double okKcal;

  /// Relative deviation that is ok (of the larger of stated and expected).
  final double okFraction;

  /// Absolute deviation (kcal) that is at most a warning.
  final double warnKcal;

  /// Relative deviation that is at most a warning.
  final double warnFraction;

  /// Stated kcal per 100 g or ml above this is a hard fail (pure fat is 900).
  final double maxKcalPer100;

  /// Grams of macros per 100 g above this is a hard fail (mass basis only:
  /// dense liquids like honey or syrup legitimately exceed 100 g per 100 ml).
  final double maxMacroGramsPer100g;
}

/// The verdict of the sanity check.
enum SanityLevel {
  /// Consistent.
  ok,

  /// Somewhat off: a gentle warning on user-created foods (FD-012).
  warn,

  /// Inconsistent or impossible: not usable as verified.
  fail,
}

/// Which carbohydrate convention explained the stated kcal best.
enum CarbConvention {
  /// Carbs include fiber, all at 4 kcal/g (US labels).
  fiberInCarbs,

  /// Carbs exclude fiber; fiber counts 2 kcal/g (EU labels).
  fiberSeparate,
}

/// Why the check gave its level.
enum SanityReason {
  /// The stated kcal matches the macros within tolerance.
  consistent,

  /// The stated kcal is off from the macros (warn or fail by size).
  kcalMismatch,

  /// A value is negative or not a number.
  invalidValue,

  /// Stated kcal per 100 is above the maximum.
  kcalTooHigh,

  /// More grams of macros than fit in 100 g.
  macrosTooHeavy,
}

/// The result of the FD-012 sanity check. It carries the expected kcal and
/// the deviation, so a review screen can highlight the values (FD-041).
final class SanityResult {
  /// A result at [level] for [reason].
  const new({
    required this.level,
    required this.reason,
    required this.expectedKcal,
    required this.deviation,
    required this.convention,
  });

  /// ok, warn or fail.
  final SanityLevel level;

  /// Why.
  final SanityReason reason;

  /// kcal expected from the macros under [convention].
  final double expectedKcal;

  /// |stated kcal − [expectedKcal]|.
  final double deviation;

  /// The carb convention closer to the stated kcal.
  final CarbConvention convention;
}

/// The FD-012 sanity check: do the stated kcal roughly match
/// 4·protein + 4·carbs + 9·fat (+ fiber, + 7·alcohol)?
///
/// Food data doesn't say whether its carbs include fiber, so the expected
/// kcal is computed both ways (S08 D5) and the closer one is used:
/// fiber in carbs `4P + 4C + 9F + 7A`, fiber separate
/// `4P + 4C + 2·fiber + 9F + 7A`. With the deviation `d`:
/// **ok** if `d ≤ max(okKcal, okFraction · max(kcal, expected))`,
/// **warn** if `d ≤ max(warnKcal, warnFraction · max(kcal, expected))`,
/// else **fail**. Hard fail regardless: a negative or non-finite value, kcal
/// above `maxKcalPer100`, or (per 100 g only) the macros of the selected
/// convention above `maxMacroGramsPer100g`: P + C + F when fiber is in the
/// carbs, P + C + F + fiber when it isn't (A4).
final class SanityCheck {
  /// A check with [tolerance].
  const new([this.tolerance = SanityTolerance.defaults]);

  /// The thresholds.
  final SanityTolerance tolerance;

  /// Checks per-100 [values] of a food on [basis].
  SanityResult check(Nutrients values, NutrientBasis basis) => checkValues(
    kcal: values.kcal,
    protein: values.protein,
    carbs: values.carbs,
    fat: values.fat,
    fiber: values.fiber,
    alcohol: values.extra(NutrientKey.alcohol) ?? 0,
    basis: basis,
  );

  /// Checks raw per-100 values before they become [Nutrients] (a label read
  /// or a catalog source can hold negative or missing-as-NaN values).
  SanityResult checkValues({
    required double kcal,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    required NutrientBasis basis,
    double alcohol = 0,
  }) {
    final base = 4 * protein + 4 * carbs + 9 * fat + 7 * alcohol;
    final fiberSeparate = base + 2 * fiber;
    final useSeparate = (kcal - fiberSeparate).abs() < (kcal - base).abs();
    final expected = useSeparate ? fiberSeparate : base;
    final deviation = (kcal - expected).abs();
    final convention = useSeparate
        ? CarbConvention.fiberSeparate
        : CarbConvention.fiberInCarbs;

    SanityResult result(SanityLevel level, SanityReason reason) => SanityResult(
      level: level,
      reason: reason,
      expectedKcal: expected,
      deviation: deviation,
      convention: convention,
    );

    final values = [kcal, protein, carbs, fat, fiber, alcohol];
    if (values.any((v) => !v.isFinite || v < 0)) {
      return result(SanityLevel.fail, SanityReason.invalidValue);
    }
    if (kcal > tolerance.maxKcalPer100) {
      return result(SanityLevel.fail, SanityReason.kcalTooHigh);
    }
    final macroGrams = protein + carbs + fat + (useSeparate ? fiber : 0);
    if (basis == NutrientBasis.per100g &&
        macroGrams > tolerance.maxMacroGramsPer100g) {
      return result(SanityLevel.fail, SanityReason.macrosTooHeavy);
    }

    final scale = math.max(kcal, expected);
    if (deviation <= math.max(tolerance.okKcal, tolerance.okFraction * scale)) {
      return result(SanityLevel.ok, SanityReason.consistent);
    }
    final warnLimit = math.max(
      tolerance.warnKcal,
      tolerance.warnFraction * scale,
    );
    return deviation <= warnLimit
        ? result(SanityLevel.warn, SanityReason.kcalMismatch)
        : result(SanityLevel.fail, SanityReason.kcalMismatch);
  }
}
