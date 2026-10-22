import 'package:fb_domain/src/food/portion/unit_options.dart';
import 'package:fb_domain/src/units/food_measures.dart';

/// Parser-independent quantity hypothesis carried from search (A07 D7).
final class ParsedAmount {
  /// Positive finite amount, with an optional explicit unit.
  new(this.amount, [this.unitCode]) {
    if (!amount.isFinite || amount <= 0) throw ArgumentError('invalid amount');
  }

  /// Parsed count.
  final double amount;

  /// Explicit unit; null means the default serving unit.
  final String? unitCode;
}

/// FD-022 default input selection, without changing the food's measures.
abstract final class DefaultPortion {
  /// Last resolvable input, then resolvable parse, then first serving or 100 g/ml.
  static Quantity choose(
    FoodMeasures measures, {
    Quantity? lastUsed,
    ParsedAmount? parsed,
  }) {
    if (lastUsed != null && measures.resolve(lastUsed) is Resolved) {
      return lastUsed;
    }
    final options = UnitOptions.of(measures);
    final servings = options.where(measures.servingUnits.containsKey);
    final fallback = servings.isEmpty
        ? Quantity(100, measures.basis.unitCode)
        : Quantity(1, servings.first);
    if (parsed != null) {
      final input = Quantity(
        parsed.amount,
        parsed.unitCode ?? fallback.unitCode,
      );
      if (measures.resolve(input) is Resolved) return input;
    }
    return fallback;
  }
}
