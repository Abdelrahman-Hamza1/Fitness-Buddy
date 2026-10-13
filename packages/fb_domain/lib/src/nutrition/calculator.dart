import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/nutrition/nutrients.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// The nutrients of one logged amount, as stored on the entry (FD-073: later
/// edits to the food never change it).
final class NutrientSnapshot {
  /// A snapshot of [nutrients] for [amount] on [basis], from [input].
  const new({
    required this.nutrients,
    required this.amount,
    required this.basis,
    this.input,
  });

  /// The entry's nutrients, at storage precision.
  final Nutrients nutrients;

  /// The canonical amount (grams or ml, see [basis]) at storage precision.
  final double amount;

  /// Whether [amount] is grams or millilitres.
  final NutrientBasis basis;

  /// The amount as the user typed it, when there was one.
  final Quantity? input;
}

/// The outcome of [NutritionCalculator.compute].
sealed class CalculationResult {
  const new();
}

/// The input resolved and the snapshot was computed.
final class Computed extends CalculationResult {
  /// The computed [snapshot].
  const new(this.snapshot);

  /// The entry's nutrient snapshot.
  final NutrientSnapshot snapshot;
}

/// The input could not be turned into a canonical amount.
final class NotComputed extends CalculationResult {
  /// Not computed because of [reason].
  const new(this.reason);

  /// Why the amount didn't resolve.
  final QuantityFailure reason;
}

/// The one nutrition calculation (`05` §1): entry nutrients = per-100 values ×
/// amount / 100. The app, `tools/catalog` and Buddy's proposals all use it.
///
/// Rounding (S08 D2, A8): the canonical amount is rounded to storage
/// precision first, because that is the amount stored on the entry, and the
/// nutrients are computed from it and rounded once. Recomputing from the
/// stored amount therefore gives the stored nutrients.
final class NutritionCalculator {
  /// The calculator. It has no state.
  const new();

  /// The snapshot for [input] of a food with [per100] values and [measures].
  CalculationResult compute({
    required Nutrients per100,
    required FoodMeasures measures,
    required Quantity input,
  }) => switch (measures.resolve(input)) {
    Resolved(:final amount, :final basis) => Computed(
      forAmount(per100: per100, amount: amount, basis: basis, input: input),
    ),
    final QuantityFailure failure => NotComputed(failure),
  };

  /// The snapshot for a canonical [amount] (grams or ml on [basis]) of a food
  /// with [per100] values. Used directly when the amount is already
  /// canonical, e.g. after a yield conversion. [amount] must be finite and
  /// not negative.
  NutrientSnapshot forAmount({
    required Nutrients per100,
    required double amount,
    required NutrientBasis basis,
    Quantity? input,
  }) {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be finite and >= 0');
    }
    final stored = StoragePrecision.round(amount);
    return NutrientSnapshot(
      nutrients: per100.scale(stored / 100).rounded(),
      amount: stored,
      basis: basis,
      input: input,
    );
  }
}
