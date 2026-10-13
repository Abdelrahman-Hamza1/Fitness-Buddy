import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/units/units.dart';

/// What a food's nutrient values are given per: 100 g (foods) or 100 ml
/// (drinks). Also the canonical unit its amounts are stored in.
enum NutrientBasis {
  /// Per 100 g, amounts in grams.
  per100g('g'),

  /// Per 100 ml, amounts in millilitres.
  per100ml('ml');

  new(this.unitCode);

  /// The canonical unit code of amounts on this basis (`g` or `ml`).
  final String unitCode;
}

/// An amount as the user typed it: the number and the unit code, kept as
/// `input_amount` / `input_unit` next to the canonical amount (`05` §1).
final class Quantity {
  /// [amount] of the unit with [unitCode]. The amount must be finite and not
  /// negative (parsers never produce anything else).
  new(this.amount, this.unitCode) {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be finite and >= 0');
    }
  }

  /// The number as typed.
  final double amount;

  /// A mass, volume, portion or food-specific unit code.
  final String unitCode;

  @override
  bool operator ==(Object other) =>
      other is Quantity && other.amount == amount && other.unitCode == unitCode;

  @override
  int get hashCode => Object.hash(amount, unitCode);

  @override
  String toString() => 'Quantity($amount $unitCode)';
}

/// A food-specific unit: how many grams (or ml) one loaf, plate, piece or
/// serving of this food is (LC-051).
final class ServingUnit {
  /// One [code] of this food weighs [grams] grams.
  new grams(this.code, double grams)
    : amount = _positive(grams),
      basis = NutrientBasis.per100g;

  /// One [code] of this food holds [milliliters] ml.
  new milliliters(this.code, double milliliters)
    : amount = _positive(milliliters),
      basis = NutrientBasis.per100ml;

  /// The unit code, usually a `PortionUnit` code. A code that is also a
  /// standard unit (`cup`, `tbsp`) shadows it for this food, on purpose: a
  /// food's own cup is more exact than the label cup and a density.
  final String code;

  /// Grams or millilitres in one unit (see [basis]).
  final double amount;

  /// Whether [amount] is grams or millilitres.
  final NutrientBasis basis;
}

/// How a food's amounts are measured: its basis, its own serving units and,
/// if known, its density (S08 D4).
///
/// Volume ↔ mass needs the density or a food-specific serving unit. Without
/// one the resolution fails with a reason; it never guesses.
final class FoodMeasures {
  /// Measures of a food on [basis] with [servingUnits] and an optional
  /// [densityGramsPerMl].
  new({
    required this.basis,
    Iterable<ServingUnit> servingUnits = const [],
    this.densityGramsPerMl,
  }) : servingUnits = _byCode(servingUnits) {
    final density = densityGramsPerMl;
    if (density != null) _positive(density);
  }

  /// Per 100 g or per 100 ml.
  final NutrientBasis basis;

  /// The food's own units, by code.
  final Map<String, ServingUnit> servingUnits;

  /// Grams per millilitre, when known.
  final double? densityGramsPerMl;

  /// The canonical amount (grams or ml on [basis]) of [input], rounded to
  /// storage precision because it is what gets stored (S08 D2, A8).
  ///
  /// A food's own serving unit wins over a generic unit with the same code
  /// (a food that says its "cup" weighs 200 g is more exact than a density).
  QuantityResolution resolve(Quantity input) {
    final serving = servingUnits[input.unitCode];
    if (serving != null) {
      return _onBasis(input.amount * serving.amount, serving.basis, input);
    }
    final mass = MassUnit.fromCode(input.unitCode);
    if (mass != null) {
      return _onBasis(input.amount * mass.grams, NutrientBasis.per100g, input);
    }
    final volume = VolumeUnit.fromCode(input.unitCode);
    if (volume != null) {
      return _onBasis(
        input.amount * volume.milliliters,
        NutrientBasis.per100ml,
        input,
      );
    }
    return UnknownServingUnit(input);
  }

  QuantityResolution _onBasis(
    double amount,
    NutrientBasis from,
    Quantity input,
  ) {
    if (from == basis) return Resolved(StoragePrecision.round(amount), basis);
    final density = densityGramsPerMl;
    if (density == null) return NeedsDensity(input);
    final converted = from == NutrientBasis.per100ml
        ? amount * density
        : amount / density;
    return Resolved(StoragePrecision.round(converted), basis);
  }

  static Map<String, ServingUnit> _byCode(Iterable<ServingUnit> units) {
    final byCode = <String, ServingUnit>{};
    for (final unit in units) {
      if (byCode.containsKey(unit.code)) {
        throw ArgumentError.value(unit.code, 'servingUnits', 'duplicate code');
      }
      byCode[unit.code] = unit;
    }
    return Map.unmodifiable(byCode);
  }
}

/// The outcome of [FoodMeasures.resolve].
sealed class QuantityResolution {
  const new();
}

/// The input as a canonical amount.
final class Resolved extends QuantityResolution {
  /// [amount] grams or ml (see [basis]), at storage precision.
  const new(this.amount, this.basis);

  /// Grams or millilitres, rounded to storage precision.
  final double amount;

  /// Whether [amount] is grams or millilitres.
  final NutrientBasis basis;
}

/// Why an input could not be turned into a canonical amount.
sealed class QuantityFailure extends QuantityResolution {
  const new(this.input);

  /// The input that failed.
  final Quantity input;
}

/// The input is a volume and the food is per 100 g (or the other way
/// round), and the food has no density.
final class NeedsDensity extends QuantityFailure {
  /// [input] needs a density to convert.
  const new(super.input);
}

/// The unit code is neither a mass or volume unit nor one of the food's own
/// serving units.
final class UnknownServingUnit extends QuantityFailure {
  /// [input] has a unit this food doesn't know.
  const new(super.input);
}

double _positive(double value) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, 'value', 'must be finite and > 0');
  }
  return value;
}
