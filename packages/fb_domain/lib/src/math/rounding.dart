import 'dart:math' as math;

/// Rounds [value] to [decimals] decimal places, ties away from zero.
///
/// `value · 10^decimals` is first cleaned to 6 decimals, so binary noise
/// doesn't decide a tie: 2.675 → 2.68 and 1.005 → 1.01 (both are stored a
/// hair below the tie as doubles). Throws an [ArgumentError] for NaN or
/// infinity, for a [decimals] outside 0…6, and when `|value · 10^decimals|`
/// is 1e15 or more (past that a double can't hold 6 clean decimals).
double roundHalfAwayFromZero(double value, int decimals) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, 'value', 'must be finite');
  }
  if (decimals < 0 || decimals > 6) {
    throw RangeError.range(decimals, 0, 6, 'decimals');
  }
  final scale = math.pow(10, decimals).toDouble();
  if ((value * scale).abs() >= _maxScaled) {
    throw ArgumentError.value(value, 'value', 'too large to round');
  }
  final cleaned = double.parse((value * scale).toStringAsFixed(6));
  // `double.round` rounds ties away from zero and returns an int, so the
  // result is never -0.0.
  return cleaned.round() / scale;
}

/// The largest `|value · 10^decimals|` [roundHalfAwayFromZero] accepts
/// (exclusive).
const double _maxScaled = 1_000_000_000_000_000;

/// The one storage rounding rule (S08 D2).
///
/// Snapshot nutrients (kcal, g, mg) and canonical amounts (g, ml, kg, cm) are
/// rounded once, to [decimals] decimals, when they are persisted or
/// snapshotted, in the unit of the persisted column. Everything before that
/// works on unrounded doubles.
abstract final class StoragePrecision {
  /// Decimal places kept in storage.
  static const int decimals = 2;

  /// [value] rounded to storage precision, ties away from zero.
  static double round(double value) => roundHalfAwayFromZero(value, decimals);
}

/// How numbers are rounded for display (S08 D3). Numbers only: the app turns
/// them into text with its localized strings.
///
/// Totals are always rounded from the **sum of stored values**, never summed
/// from displayed values, so a day total is the same in every view.
abstract final class DisplayRounding {
  /// Energy: whole kcal.
  static int kcal(double kcal) => _whole(kcal);

  /// A nutrient in grams: 1 decimal below 10 g, whole grams from 10 g.
  static double nutrientGrams(double grams) {
    final tenth = roundHalfAwayFromZero(grams, 1);
    return tenth.abs() < 10 ? tenth : _whole(grams).toDouble();
  }

  /// A daily macro target in grams (TG-050–055): whole grams, so "82 / 140 g"
  /// compares an eaten amount with a round target.
  static int macroTargetGrams(double grams) => _whole(grams);

  /// A nutrient in milligrams: whole mg.
  static int milligrams(double milligrams) => _whole(milligrams);

  /// A food amount in grams or millilitres: whole numbers.
  static int foodAmount(double gramsOrMl) => _whole(gramsOrMl);

  /// Body weight in kg or lb, ounces, fluid ounces: 1 decimal.
  static double oneDecimal(double value) => roundHalfAwayFromZero(value, 1);

  /// Lengths in cm or inches: whole numbers.
  static int length(double cmOrInches) => _whole(cmOrInches);

  static int _whole(double value) => roundHalfAwayFromZero(value, 0).toInt();
}
