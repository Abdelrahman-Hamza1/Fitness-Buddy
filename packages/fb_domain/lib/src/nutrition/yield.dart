import 'package:fb_domain/src/food/food_state.dart';
import 'package:fb_domain/src/math/rounding.dart';
import 'package:fb_domain/src/units/amounts.dart';

/// One yield row (FD-060): [factor] grams of [to] per gram of [from] for a
/// food [group], e.g. rice dry → cooked × 2.5. The rows come from the catalog
/// (S13).
final class YieldFactor {
  /// A row. [factor] must be finite and positive.
  new({
    required this.group,
    required this.from,
    required this.to,
    required this.factor,
  }) {
    if (!factor.isFinite || factor <= 0) {
      throw ArgumentError.value(factor, 'factor', 'must be finite and > 0');
    }
    if (from == to) {
      throw ArgumentError.value(to, 'to', 'must differ from from');
    }
  }

  /// The food group the factor applies to (a catalog group code, e.g. `rice`).
  final String group;

  /// The state of the known amount.
  final FoodState from;

  /// The state converted to.
  final FoodState to;

  /// Grams in [to] per gram in [from].
  final double factor;
}

/// A yield conversion and the note shown to the user (FD-062):
/// "200 g dry ≈ 500 g cooked". The words come from the app's strings.
final class YieldNote {
  /// [fromAmount] in [fromState] is [toAmount] in [toState] by [factor].
  const new({
    required this.fromAmount,
    required this.fromState,
    required this.toAmount,
    required this.toState,
    required this.factor,
  });

  /// The amount the user stated.
  final Mass fromAmount;

  /// The stated state.
  final FoodState fromState;

  /// The exact converted amount. This is what the calculator uses (A8).
  final Mass toAmount;

  /// The state of the matched food.
  final FoodState toState;

  /// Grams in [toState] per gram in [fromState].
  final double factor;

  /// The converted amount as the note shows it, in grams: to the nearest
  /// 5 g from 50 g, else whole grams, because "≈ 487 g" reads falsely exact
  /// (S08 D6). Only for the text; never use it for nutrients.
  int get toGramsForNote {
    final grams = toAmount.grams;
    return grams >= 50
        ? roundHalfAwayFromZero(grams / 5, 0).toInt() * 5
        : DisplayRounding.foodAmount(grams);
  }
}

/// Converts amounts between food states with data-driven factors (FD-060).
///
/// It converts the **amount** (500 g cooked rice → 200 g dry); the calculator
/// then uses the matched food's own per-100 g values, so there is only one
/// nutrient calculation (S08 D6). A direct row is used, else the inverse of
/// the reverse row. Rows are never chained.
final class YieldConverter {
  /// A converter over [factors]. Two rows for the same group and direction
  /// are a data error.
  new(Iterable<YieldFactor> factors) : _factors = _index(factors);

  final Map<(String, FoodState, FoodState), double> _factors;

  /// [amount] of [group] in state [from], converted to state [to], or `null`
  /// when there is no factor for the pair. The same state converts with
  /// factor 1.
  YieldNote? convert({
    required Mass amount,
    required String group,
    required FoodState from,
    required FoodState to,
  }) {
    final factor = from == to ? 1.0 : _factorFor(group, from, to);
    if (factor == null) return null;
    return YieldNote(
      fromAmount: amount,
      fromState: from,
      toAmount: amount * factor,
      toState: to,
      factor: factor,
    );
  }

  double? _factorFor(String group, FoodState from, FoodState to) {
    final direct = _factors[(group, from, to)];
    if (direct != null) return direct;
    final reverse = _factors[(group, to, from)];
    return reverse == null ? null : 1 / reverse;
  }

  static Map<(String, FoodState, FoodState), double> _index(
    Iterable<YieldFactor> factors,
  ) {
    final index = <(String, FoodState, FoodState), double>{};
    for (final row in factors) {
      final key = (row.group, row.from, row.to);
      if (index.containsKey(key)) {
        throw ArgumentError.value(
          '${row.group} ${row.from.code}→${row.to.code}',
          'factors',
          'duplicate yield row',
        );
      }
      index[key] = row.factor;
    }
    return index;
  }
}
