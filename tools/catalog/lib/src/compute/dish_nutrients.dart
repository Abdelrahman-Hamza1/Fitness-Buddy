import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_domain/fb_domain.dart';

/// Per-100 g values of a variant: the typical value and the low and high
/// bounds that follow from the recipe ranges (A03 D6). Stored at storage
/// precision.
class DishPer100 {
  const new({required this.typical, required this.low, required this.high});

  final Nutrients typical;
  final Nutrients low;
  final Nutrients high;
}

/// The ingredient could not be resolved to per-100 g values.
class ComputeException implements Exception {
  const new(this.message, {this.unresolved = false});

  final String message;

  /// The ID points at nothing (reported on its own by the validator).
  final bool unresolved;

  @override
  String toString() => message;
}

/// Per-100 g of [variant] (A03 D6). [per100Of] gives the typical per-100 g of
/// an ingredient by catalog ID.
///
/// typical = sum(grams * per100 / 100) / cooked_total_g * 100. The low bound
/// takes every ranged ingredient at its low, over the high end of
/// `cooked_total_range` (more weight, thinner); the high bound the reverse.
/// Ingredients without a range stay at their typical grams. The value is
/// rounded once, at the end. A `per_100g` variant is returned as stated.
DishPer100 computeVariant(
  Variant variant,
  Nutrients Function(String food) per100Of,
) {
  final stated = variant.per100g;
  if (stated != null) {
    final fixed = stated.rounded();
    return DishPer100(typical: fixed, low: fixed, high: fixed);
  }
  final recipe = variant.recipe!;
  final total = variant.cookedTotalG!;
  final foods = [for (final item in recipe) per100Of(item.food)];

  Nutrients per100(double Function(RecipeItem) grams, double cookedG) {
    final whole = Nutrients.sum([
      for (var i = 0; i < recipe.length; i++)
        foods[i].scale(grams(recipe[i]) / 100),
    ]);
    return whole.scale(100 / cookedG).rounded();
  }

  final totalRange = variant.cookedTotalRange;
  return DishPer100(
    typical: per100((i) => i.grams, total),
    low: per100((i) => i.range?.lo ?? i.grams, totalRange?.hi ?? total),
    high: per100((i) => i.range?.hi ?? i.grams, totalRange?.lo ?? total),
  );
}

/// Resolves ingredient IDs against the basics and the other dishes and
/// computes (and remembers) every variant.
class DishComputer {
  new({required this._basics, required Iterable<ReferenceDish> dishes})
    : _dishes = {for (final d in dishes) d.id: d};

  final Map<String, Nutrients> _basics;
  final Map<String, ReferenceDish> _dishes;
  final _done = <String, DishPer100>{};
  final _stack = <String>[];

  /// The values of the variant `ref:<dish>/<variant>`.
  DishPer100 variant(String id) {
    final cached = _done[id];
    if (cached != null) return cached;
    if (_stack.contains(id)) {
      throw ComputeException(
        'circular recipe: ${[..._stack, id].join(' -> ')}',
      );
    }
    final slash = id.indexOf('/');
    final dish = _dishes[slash < 0 ? id : id.substring(0, slash)];
    final v = dish == null
        ? null
        : slash < 0
        ? dish.defaultVariant
        : [
            for (final x in dish.variants)
              if (dish.variantId(x) == id) x,
          ].firstOrNull;
    if (dish == null || v == null) {
      throw ComputeException(
        '`$id` is not a known dish or variant',
        unresolved: true,
      );
    }
    _stack.add(id);
    try {
      return _done[id] = computeVariant(v, typicalOf);
    } finally {
      _stack.removeLast();
    }
  }

  /// Typical per-100 g of a catalog ID: a basic, a dish (its default
  /// variant) or a variant.
  Nutrients typicalOf(String food) {
    if (food.startsWith('usda:')) {
      return _basics[food] ??
          (throw ComputeException(
            '`$food` is not in the USDA selection or has no extract line',
            unresolved: true,
          ));
    }
    final slash = food.indexOf('/');
    if (slash < 0) {
      final def = _dishes[food]?.defaultVariant;
      if (def == null) {
        throw ComputeException('`$food` is not a known dish', unresolved: true);
      }
      return variant('$food/${def.slug}').typical;
    }
    return variant(food).typical;
  }
}
