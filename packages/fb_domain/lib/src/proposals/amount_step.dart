import 'package:fb_domain/src/units/food_measures.dart';

/// The card's − / + on an assumed amount (A22b E3, AI-040): the next amount
/// up or down in the same unit. Pure; the engine recomputes the nutrients.
///
/// - grams and millilitres move by 5 below 50, by 10 below 200, else by 25;
/// - every other unit (pieces, spoons, cups, servings) moves by 1, and by
///   0.5 at or below 1.
///
/// Down never goes below the smallest step (5 g/ml, 0.5 of a unit), and a
/// value off the grid snaps to the next grid value in that direction.
abstract final class AmountStep {
  /// The smallest amount − reaches in [unitCode].
  static double smallest(String unitCode) => _metric(unitCode) ? 5 : 0.5;

  /// [current] one step up.
  static Quantity up(Quantity current) {
    final a = current.amount;
    final step = _step(current.unitCode, a, up: true);
    return Quantity(_snap(a, step, up: true), current.unitCode);
  }

  /// [current] one step down, never below [smallest]; `null` when it's
  /// already there (− is then disabled).
  static Quantity? down(Quantity current) {
    final min = smallest(current.unitCode);
    final a = current.amount;
    if (a <= min) return null;
    final step = _step(current.unitCode, a, up: false);
    final next = _snap(a, step, up: false);
    return Quantity(next < min ? min : next, current.unitCode);
  }

  static bool _metric(String unitCode) => unitCode == 'g' || unitCode == 'ml';

  // The step that applies on the way from [a] in that direction: going down
  // from exactly 50 uses the smaller step below it.
  static double _step(String unitCode, double a, {required bool up}) {
    if (_metric(unitCode)) {
      final at = up ? a : a - 1e-9;
      if (at < 50) return 5;
      if (at < 200) return 10;
      return 25;
    }
    return (up ? a < 1 : a <= 1 + 1e-9) ? 0.5 : 1;
  }

  // The next multiple of [step] strictly past [a].
  static double _snap(double a, double step, {required bool up}) {
    final units = a / step;
    final n = up
        ? (units + 1e-9).floorToDouble() + 1
        : (units - 1e-9).ceilToDouble() - 1;
    return n * step;
  }
}
