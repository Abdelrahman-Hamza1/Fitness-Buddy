import 'package:fb_domain/src/units/food_measures.dart';
import 'package:fb_domain/src/units/units.dart';

/// Resolvable unit chips in FD-022/LC-011 order, without duplicate codes.
abstract final class UnitOptions {
  /// Food-specific portion priority; unknown codes follow alphabetically.
  static const servingPriority = [
    'loaf',
    'piece',
    'plate',
    'small_plate',
    'large_plate',
    'bowl',
    'glass',
    'can',
    'sandwich',
    'disc',
    'slice',
    'wedge',
    'container',
    'ladle',
    'serving',
    'cup',
    'tbsp',
    'tsp',
  ];

  /// Servings lead, then system units; every resolvable input stays available.
  static List<String> of(
    FoodMeasures measures, {
    UnitSystem system = UnitSystem.metric,
  }) {
    final servings = measures.servingUnits.keys.toList()
      ..sort((a, b) {
        final ai = servingPriority.indexOf(a);
        final bi = servingPriority.indexOf(b);
        final priority = (ai < 0 ? servingPriority.length : ai).compareTo(
          bi < 0 ? servingPriority.length : bi,
        );
        return priority != 0 ? priority : a.compareTo(b);
      });
    return {
      ...servings,
      if (system == UnitSystem.imperial) ...[
        if (measures.basis == NutrientBasis.per100g) ...[
          'oz',
          'lb',
          'g',
          'kg',
          'fl_oz',
          'cup',
          'tbsp',
          'tsp',
          'ml',
          'l',
        ] else ...[
          'fl_oz',
          'cup',
          'tbsp',
          'tsp',
          'ml',
          'l',
          'oz',
          'lb',
          'g',
          'kg',
        ],
      ],
      measures.basis.unitCode,
      'g',
      'oz',
      'lb',
      'kg',
      'ml',
      'cup',
      'tbsp',
      'tsp',
      'fl_oz',
      'l',
    }.where((code) => measures.resolve(Quantity(1, code)) is Resolved).toList();
  }
}
