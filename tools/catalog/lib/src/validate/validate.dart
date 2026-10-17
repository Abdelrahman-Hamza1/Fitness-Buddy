import 'package:fb_catalog/src/compute/dish_nutrients.dart';
import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/model/issue.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_text/fb_text.dart';

/// What `validateCatalog` found.
class ValidationReport {
  /// Problems that fail the build.
  final errors = <CatalogIssue>[];

  /// Sanity warnings (A03 D7): reported, the build continues.
  final warnings = <CatalogIssue>[];

  /// Sanity failures waived by a reviewed `sanity_override`, with the reason.
  final overrides = <CatalogIssue>[];

  /// Per-100 g of every variant that resolved, by `ref:<dish>/<variant>`.
  final computed = <String, DishPer100>{};
}

final _offUrl = RegExp(r'openfoodfacts\.', caseSensitive: false);

/// The semantic rules the JSON Schema can't express: references resolve,
/// exactly one default variant, ordered ranges, no Open Food Facts source
/// (C-5), unique normalized names per language (FD-004), and the FD-012
/// sanity check on every basic and variant (A03 D7).
ValidationReport validateCatalog({
  required List<BasicFood> basics,
  required List<ReferenceDish> dishes,
  bool requireAr = false,
  SanityCheck sanity = const SanityCheck(),
}) {
  final report = ValidationReport();
  final sortedDishes = [...dishes]..sort((a, b) => a.id.compareTo(b.id));
  _basics(report, basics, requireAr, sanity);
  final known = {for (final b in basics) b.id};
  final computer = DishComputer(
    basics: {
      for (final b in basics)
        if (b.nutrients != null) b.id: b.nutrients!,
    },
    dishes: sortedDishes,
  );
  final seenDish = <String>{};
  for (final dish in sortedDishes) {
    if (!seenDish.add(dish.id)) {
      report.errors.add(
        CatalogIssue(dish.file, '/id', 'duplicate dish id ${dish.id}'),
      );
    }
    _dish(report, dish, known, sortedDishes, computer, sanity);
  }
  _names(report, basics, sortedDishes);
  return report;
}

void _basics(
  ValidationReport report,
  List<BasicFood> basics,
  bool requireAr,
  SanityCheck sanity,
) {
  final seen = <String>{};
  for (final b in basics) {
    final at = '/foods/${b.index}';
    if (!seen.add(b.id)) {
      report.errors.add(CatalogIssue(b.file, '$at/id', 'duplicate id ${b.id}'));
    }
    if (requireAr && b.names['ar'] == null) {
      report.errors.add(
        CatalogIssue(b.file, '$at/names', '${b.id}: names.ar is required'),
      );
    }
    final n = b.nutrients;
    if (n == null) {
      report.errors.add(
        CatalogIssue(
          b.file,
          '$at/id',
          '${b.id} has no line in the extract (run `catalog import-usda`)',
        ),
      );
      continue;
    }
    _sanity(report, sanity, n, b.id, b.file, at, b.sanityOverrideReason);
  }
}

void _sanity(
  ValidationReport report,
  SanityCheck sanity,
  Nutrients values,
  String id,
  String file,
  String path,
  String? override,
) {
  final r = sanity.check(values, NutrientBasis.per100g);
  if (r.level == SanityLevel.ok) return;
  final text =
      '$id per 100 g: ${values.kcal} kcal, P ${values.protein}, '
      'C ${values.carbs}, F ${values.fat}, fiber ${values.fiber}; '
      'macros give ${r.expectedKcal.toStringAsFixed(0)} kcal '
      '(${r.reason.name}, off by ${r.deviation.toStringAsFixed(0)})';
  if (r.level == SanityLevel.warn) {
    report.warnings.add(CatalogIssue(file, path, 'sanity warn: $text'));
  } else if (override != null) {
    report.overrides.add(
      CatalogIssue(file, path, 'sanity fail waived ($override): $text'),
    );
  } else {
    report.errors.add(CatalogIssue(file, path, 'sanity fail: $text'));
  }
}

void _dish(
  ValidationReport report,
  ReferenceDish dish,
  Set<String> basicIds,
  List<ReferenceDish> allDishes,
  DishComputer computer,
  SanityCheck sanity,
) {
  void error(String path, String message) =>
      report.errors.add(CatalogIssue(dish.file, path, message));

  final fileName = dish.file.split(RegExp(r'[/\\]')).last;
  if (fileName != '${dish.slug}.yaml') {
    error('/id', 'file name must be ${dish.slug}.yaml for id ${dish.id}');
  }
  for (var i = 0; i < dish.review.sources.length; i++) {
    _offSource(error, '/review/sources/$i', dish.review.sources[i]);
  }
  _portionRanges(error, '/portions', dish.portions);

  final defaults = dish.variants.where((v) => v.isDefault).length;
  if (defaults != 1) {
    error('/variants', 'exactly one variant must be default, found $defaults');
  }
  final slugs = <String>{};
  for (var vi = 0; vi < dish.variants.length; vi++) {
    final v = dish.variants[vi];
    final at = '/variants/$vi';
    if (!slugs.add(v.slug)) {
      error('$at/id', 'duplicate variant id `${v.slug}`');
    }
    if (v.nutrientSource != null) {
      _offSource(error, '$at/nutrient_source', v.nutrientSource!);
    }
    _portionRanges(error, '$at/portions', v.portions);
    final recipe = v.recipe;
    if (recipe != null) {
      for (var ri = 0; ri < recipe.length; ri++) {
        final item = recipe[ri];
        final range = item.range;
        if (range != null) {
          _range(error, '$at/recipe/$ri/range', range, item.grams, 'grams');
        }
        if (!_resolves(item.food, basicIds, allDishes)) {
          error(
            '$at/recipe/$ri/food',
            '`${item.food}` does not resolve to a USDA basic or a '
                'reference dish',
          );
        }
      }
      final cooked = v.cookedTotalRange;
      if (cooked != null) {
        _range(
          error,
          '$at/cooked_total_range',
          cooked,
          v.cookedTotalG!,
          'cooked_total_g',
        );
      }
    }
    final id = dish.variantId(v);
    try {
      final values = computer.variant(id);
      report.computed[id] = values;
      _sanity(
        report,
        sanity,
        values.typical,
        id,
        dish.file,
        at,
        v.sanityOverrideReason ?? dish.sanityOverrideReason,
      );
    } on ComputeException catch (e) {
      // An unresolved reference is reported on its recipe line.
      if (!e.unresolved) error(at, e.message);
    }
  }
}

void _offSource(
  void Function(String path, String message) error,
  String path,
  String source,
) {
  if (_offUrl.hasMatch(source)) {
    error(
      path,
      'Open Food Facts is not allowed as a source (ODbL isolation, C-5): '
      '$source',
    );
  }
}

void _range(
  void Function(String path, String message) error,
  String path,
  Range range,
  double typical,
  String what,
) {
  if (range.lo > range.hi) {
    error(path, 'range $range: low is above high');
  } else if (!range.contains(typical)) {
    error(path, '$what ${_fmt(typical)} is outside its range $range');
  }
}

String _fmt(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

void _portionRanges(
  void Function(String path, String message) error,
  String path,
  Map<String, Portion> portions,
) {
  for (final MapEntry(key: code, value: portion) in portions.entries) {
    _range(error, '$path/$code/range', portion.range, portion.g, 'g');
  }
}

bool _resolves(String food, Set<String> basicIds, List<ReferenceDish> dishes) {
  if (food.startsWith('usda:')) return basicIds.contains(food);
  final slash = food.indexOf('/');
  final dishId = slash < 0 ? food : food.substring(0, slash);
  for (final d in dishes) {
    if (d.id != dishId) continue;
    return slash < 0 || d.variants.any((v) => d.variantId(v) == food);
  }
  return false;
}

/// FD-004: within one language, a normalized name belongs to one item (a
/// dish and its variants count as one).
void _names(
  ValidationReport report,
  List<BasicFood> basics,
  List<ReferenceDish> dishes,
) {
  final owners = <String, ({String owner, String name})>{};
  void add(
    String file,
    String path,
    String owner,
    String lang,
    List<String> names,
  ) {
    for (var i = 0; i < names.length; i++) {
      final key = normalizeKey(names[i]);
      final at = '$path/$lang/$i';
      if (key.isEmpty) {
        report.errors.add(
          CatalogIssue(file, at, 'name "${names[i]}" has no searchable text'),
        );
        continue;
      }
      final slot = '$lang\u0000$key';
      final first = owners[slot];
      if (first == null) {
        owners[slot] = (owner: owner, name: names[i]);
      } else if (first.owner != owner) {
        report.errors.add(
          CatalogIssue(
            file,
            at,
            'duplicate $lang name "${names[i]}" (same search key "$key" as '
            '"${first.name}" of ${first.owner})',
          ),
        );
      }
    }
  }

  for (final b in basics) {
    for (final lang in nameLanguages) {
      add(b.file, '/foods/${b.index}/names', b.id, lang, b.names[lang] ?? []);
    }
  }
  for (final d in dishes) {
    for (final lang in nameLanguages) {
      add(d.file, '/names', d.id, lang, d.names[lang] ?? []);
    }
    for (var vi = 0; vi < d.variants.length; vi++) {
      for (final lang in nameLanguages) {
        add(
          d.file,
          '/variants/$vi/names',
          d.id,
          lang,
          d.variants[vi].names[lang] ?? [],
        );
      }
    }
  }
}
