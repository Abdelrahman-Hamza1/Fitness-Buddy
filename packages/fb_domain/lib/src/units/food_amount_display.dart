import 'package:fb_domain/src/units/amounts.dart';
import 'package:fb_domain/src/units/display.dart';
import 'package:fb_domain/src/units/food_measures.dart';
import 'package:fb_domain/src/units/units.dart';

/// Primary input quantity; portion words retain the exact typed number.
final class DisplayQuantity {
  /// Creates a presentation value without display text.
  const new(this.value, this.unitCode, {required this.converted});

  /// Number to format.
  final double value;

  /// Stable input or display unit code.
  final String unitCode;

  /// Whether standard-unit display rules were applied.
  final bool converted;
}

/// LC-011 / A10 PA2: conversions stay in the input's own dimension.
final class FoodAmountDisplay {
  const new _(this.primary, this.secondary);

  /// Formats quantities only; never resolves density or changes stored input.
  factory of({
    required Quantity input,
    required double amount,
    required NutrientBasis basis,
    required UnitSystem system,
  }) {
    final mass = MassUnit.fromCode(input.unitCode);
    final volume = VolumeUnit.fromCode(input.unitCode);
    final standardVolume =
        volume != null && const ['ml', 'l', 'fl_oz'].contains(input.unitCode);
    final DisplayAmount? converted;
    if (mass != null) {
      converted = system.showFoodMass(Mass.of(input.amount, mass));
    } else if (standardVolume) {
      converted = system.showVolume(Volume.of(input.amount, volume));
    } else {
      converted = null;
    }
    final sameDimension =
        mass != null && basis == NutrientBasis.per100g ||
        standardVolume && basis == NutrientBasis.per100ml;
    final secondary = sameDimension
        ? null
        : basis == NutrientBasis.per100g
        ? system.showFoodMass(Mass.grams(amount))
        : system.showVolume(Volume.milliliters(amount));
    return FoodAmountDisplay._(
      DisplayQuantity(
        converted?.value ?? input.amount,
        converted?.unitCode ?? input.unitCode,
        converted: converted != null,
      ),
      secondary,
    );
  }

  /// Input in its own dimension, or an unchanged portion/kitchen word.
  final DisplayQuantity primary;

  /// Canonical quantity, only when it adds information.
  final DisplayAmount? secondary;
}
