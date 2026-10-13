import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/units/units.dart';

/// Shared arithmetic of the canonical amount types: an immutable, finite
/// double in the canonical unit (g, ml, cm, kcal). Values may be negative
/// (a weight change); rules that need a non-negative amount check it.
abstract base class _Amount<T extends _Amount<T>> implements Comparable<T> {
  new(this._value, String name) {
    if (!_value.isFinite) {
      throw ArgumentError.value(_value, name, 'must be finite');
    }
  }

  final double _value;

  T _create(double value);

  /// The sum of this and [other].
  T operator +(T other) => _create(_value + other._value);

  /// The difference of this and [other].
  T operator -(T other) => _create(_value - other._value);

  /// This amount scaled by [factor].
  T operator *(double factor) => _create(_value * factor);

  /// Whether this is less than [other].
  bool operator <(T other) => _value < other._value;

  /// Whether this is less than or equal to [other].
  bool operator <=(T other) => _value <= other._value;

  /// Whether this is greater than [other].
  bool operator >(T other) => _value > other._value;

  /// Whether this is greater than or equal to [other].
  bool operator >=(T other) => _value >= other._value;

  /// This amount rounded to storage precision (S08 D2), in the canonical
  /// unit.
  T roundedForStorage() => _create(StoragePrecision.round(_value));

  @override
  int compareTo(T other) => _value.compareTo(other._value);

  @override
  bool operator ==(Object other) => other is T && other._value == _value;

  @override
  int get hashCode => Object.hash(runtimeType, _value);
}

/// A mass, canonically in grams.
final class Mass extends _Amount<Mass> {
  /// A mass of [grams] grams.
  new grams(double grams) : super(grams, 'grams');

  /// A mass of [kilograms] kilograms.
  new kilograms(double kilograms) : this.grams(kilograms * 1000);

  /// A mass of [amount] in [unit] (LC-011).
  new of(double amount, MassUnit unit) : this.grams(amount * unit.grams);

  /// No mass.
  static final Mass zero = Mass.grams(0);

  /// Grams (canonical, food).
  double get grams => _value;

  /// Kilograms (canonical, body and lifted weight).
  double get kilograms => _value / 1000;

  /// This mass expressed in [unit].
  double inUnit(MassUnit unit) => _value / unit.grams;

  @override
  Mass _create(double value) => Mass.grams(value);

  @override
  String toString() => 'Mass($_value g)';
}

/// A volume, canonically in millilitres.
final class Volume extends _Amount<Volume> {
  /// A volume of [milliliters] ml.
  new milliliters(double milliliters) : super(milliliters, 'milliliters');

  /// A volume of [amount] in [unit] (LC-011).
  new of(double amount, VolumeUnit unit)
    : this.milliliters(amount * unit.milliliters);

  /// No volume.
  static final Volume zero = Volume.milliliters(0);

  /// Millilitres (canonical).
  double get milliliters => _value;

  /// This volume expressed in [unit].
  double inUnit(VolumeUnit unit) => _value / unit.milliliters;

  @override
  Volume _create(double value) => Volume.milliliters(value);

  @override
  String toString() => 'Volume($_value ml)';
}

/// A length (height, body measurements), canonically in centimetres.
final class Length extends _Amount<Length> {
  /// A length of [centimeters] cm.
  new centimeters(double centimeters) : super(centimeters, 'centimeters');

  /// A length of [amount] in [unit] (LC-011).
  new of(double amount, LengthUnit unit)
    : this.centimeters(amount * unit.centimeters);

  /// A length of [feet] feet and [inches] inches (an imperial height).
  new feetAndInches(double feet, double inches)
    : this.centimeters(
        feet * LengthUnit.foot.centimeters +
            inches * LengthUnit.inch.centimeters,
      );

  /// Centimetres (canonical).
  double get centimeters => _value;

  /// This length expressed in [unit].
  double inUnit(LengthUnit unit) => _value / unit.centimeters;

  /// This length as whole feet and whole inches, for showing a height in the
  /// imperial setting (LC-010). The total is rounded to whole inches first,
  /// so 182.88 cm is 6 ft 0 in, never 5 ft 12 in.
  ({int feet, int inches}) toFeetAndInches() {
    final totalInches = DisplayRounding.length(inUnit(LengthUnit.inch));
    return (feet: totalInches ~/ 12, inches: totalInches % 12);
  }

  @override
  Length _create(double value) => Length.centimeters(value);

  @override
  String toString() => 'Length($_value cm)';
}

/// Energy, always in kcal (LC-012: kJ is a later release, and there is no
/// other unit to convert to).
final class Energy extends _Amount<Energy> {
  /// An energy of [kcal] kilocalories.
  new kcal(double kcal) : super(kcal, 'kcal');

  /// No energy.
  static final Energy zero = Energy.kcal(0);

  /// Kilocalories.
  double get kcal => _value;

  @override
  Energy _create(double value) => Energy.kcal(value);

  @override
  String toString() => 'Energy($_value kcal)';
}
