/// Units of mass with their factor to grams (S08 D4).
///
/// Implements LC-011 (any unit is accepted): the factors are the exact
/// international definitions.
enum MassUnit {
  /// Gram, the canonical food unit.
  gram('g', 1),

  /// Kilogram, the canonical body and lifted-weight unit.
  kilogram('kg', 1000),

  /// Avoirdupois ounce (exact).
  ounce('oz', 28.349523125),

  /// Avoirdupois pound (exact).
  pound('lb', 453.59237);

  new(this.code, this.grams);

  /// The stable code stored with the original input (`input_unit`).
  final String code;

  /// Grams in one of this unit.
  final double grams;

  /// The unit whose [code] is exactly [code], or `null`.
  static MassUnit? fromCode(String code) =>
      _byCode(values, code, (u) => u.code);
}

/// Units of volume with their factor to millilitres (S08 D4).
///
/// Cup, tablespoon and teaspoon use the US nutrition-label values, the ones
/// packaged food states. Fluid ounce is the US customary one, so a 12 fl oz
/// can is 355 ml.
enum VolumeUnit {
  /// Millilitre, the canonical drink unit.
  milliliter('ml', 1),

  /// Litre.
  liter('l', 1000),

  /// US fluid ounce.
  fluidOunce('fl_oz', 29.5735295625),

  /// Nutrition-label cup.
  cup('cup', 240),

  /// Nutrition-label tablespoon.
  tablespoon('tbsp', 15),

  /// Nutrition-label teaspoon.
  teaspoon('tsp', 5);

  new(this.code, this.milliliters);

  /// The stable code stored with the original input (`input_unit`).
  final String code;

  /// Millilitres in one of this unit.
  final double milliliters;

  /// The unit whose [code] is exactly [code], or `null`.
  static VolumeUnit? fromCode(String code) =>
      _byCode(values, code, (u) => u.code);
}

/// Units of length with their factor to centimetres (S08 D4).
enum LengthUnit {
  /// Centimetre, the canonical measurement unit.
  centimeter('cm', 1),

  /// Inch (exact).
  inch('in', 2.54),

  /// Foot, 12 inches.
  foot('ft', 30.48);

  new(this.code, this.centimeters);

  /// The stable code stored with the original input.
  final String code;

  /// Centimetres in one of this unit.
  final double centimeters;

  /// The unit whose [code] is exactly [code], or `null`.
  static LengthUnit? fromCode(String code) =>
      _byCode(values, code, (u) => u.code);
}

/// Portion words with a food-specific weight (LC-051, FD-003).
///
/// A portion has no fixed size: each food says how many grams (or ml) its
/// loaf, plate or glass holds, in a `ServingUnit` with the same code.
enum PortionUnit {
  /// A piece (حبة): one fruit, one egg, one falafel.
  piece('piece'),

  /// A loaf of flat bread (رغيف).
  loaf('loaf'),

  /// A plate (صحن).
  plate('plate'),

  /// A glass (كاسة), a food-specific volume unlike the label `cup`.
  glass('glass'),

  /// A sandwich (سندويشة).
  sandwich('sandwich'),

  /// A disc (قرص), e.g. a round of taameya or ka'ak.
  disc('disc'),

  /// One serving as the food data defines it.
  serving('serving');

  new(this.code);

  /// The stable code stored with the original input (`input_unit`).
  final String code;

  /// The portion whose [code] is exactly [code], or `null`.
  static PortionUnit? fromCode(String code) =>
      _byCode(values, code, (u) => u.code);
}

/// Whether [code] names a mass, volume or portion unit known to the domain.
///
/// Parsers (`fb_text`) produce plain code strings, and this is the check that
/// they all mean something here.
bool isKnownFoodUnitCode(String code) =>
    MassUnit.fromCode(code) != null ||
    VolumeUnit.fromCode(code) != null ||
    PortionUnit.fromCode(code) != null;

/// The unit setting (LC-010): what the app *displays*. Input in any unit is
/// always accepted whatever the setting (LC-011).
enum UnitSystem {
  /// Grams, millilitres, kilograms, centimetres (the default).
  metric(
    foodMass: MassUnit.gram,
    bodyMass: MassUnit.kilogram,
    volume: VolumeUnit.milliliter,
    length: LengthUnit.centimeter,
  ),

  /// Ounces, fluid ounces, pounds, feet and inches.
  imperial(
    foodMass: MassUnit.ounce,
    bodyMass: MassUnit.pound,
    volume: VolumeUnit.fluidOunce,
    length: LengthUnit.inch,
  );

  new({
    required this.foodMass,
    required this.bodyMass,
    required this.volume,
    required this.length,
  });

  /// The setting a new profile starts with (LC-010).
  static const UnitSystem defaultSystem = metric;

  /// The unit food amounts are shown in.
  final MassUnit foodMass;

  /// The unit body weight and lifted weight are shown in.
  final MassUnit bodyMass;

  /// The unit drink amounts are shown in.
  final VolumeUnit volume;

  /// The unit body measurements are shown in (height in imperial is shown as
  /// feet and inches, see `Length.feetAndInches`).
  final LengthUnit length;
}

T? _byCode<T>(List<T> values, String code, String Function(T) codeOf) {
  for (final value in values) {
    if (codeOf(value) == code) return value;
  }
  return null;
}
