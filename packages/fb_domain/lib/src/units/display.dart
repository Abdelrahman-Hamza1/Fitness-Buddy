import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/units/amounts.dart';
import 'package:fb_domain/src/units/units.dart';

/// A number ready to show, with the code of its unit. The app formats the
/// text (digits, unit word) from its localized strings.
final class DisplayAmount {
  /// A [value] in the unit with [unitCode].
  const new(this.value, this.unitCode);

  /// The rounded number (S08 D3).
  final double value;

  /// The unit's stable code (`g`, `oz`, `kg`, `lb`, `ml`, `fl_oz`, `cm`,
  /// `in`).
  final String unitCode;

  @override
  bool operator ==(Object other) =>
      other is DisplayAmount &&
      other.value == value &&
      other.unitCode == unitCode;

  @override
  int get hashCode => Object.hash(value, unitCode);

  @override
  String toString() => 'DisplayAmount($value $unitCode)';
}

/// Display follows the unit setting (LC-010, LC-011), with the D3 rounding.
extension UnitSystemDisplay on UnitSystem {
  /// A food amount: whole grams, or ounces with 1 decimal.
  DisplayAmount showFoodMass(Mass mass) => switch (this) {
    UnitSystem.metric => _whole(mass.grams, foodMass.code),
    UnitSystem.imperial => _oneDecimal(mass.inUnit(foodMass), foodMass.code),
  };

  /// Body or lifted weight: kg or lb, 1 decimal.
  DisplayAmount showBodyMass(Mass mass) =>
      _oneDecimal(mass.inUnit(bodyMass), bodyMass.code);

  /// A drink amount: whole millilitres, or fluid ounces with 1 decimal.
  DisplayAmount showVolume(Volume amount) => switch (this) {
    UnitSystem.metric => _whole(amount.milliliters, volume.code),
    UnitSystem.imperial => _oneDecimal(amount.inUnit(volume), volume.code),
  };

  /// A body measurement: whole cm or whole inches. Heights in the imperial
  /// setting use `Length.toFeetAndInches` instead.
  DisplayAmount showLength(Length amount) =>
      _whole(amount.inUnit(length), length.code);
}

DisplayAmount _whole(double value, String code) =>
    DisplayAmount(DisplayRounding.foodAmount(value).toDouble(), code);

DisplayAmount _oneDecimal(double value, String code) =>
    DisplayAmount(DisplayRounding.oneDecimal(value), code);
