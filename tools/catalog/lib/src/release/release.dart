import 'package:fb_catalog/src/load/load_catalog.dart';
import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/validate/report.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_text/fb_text.dart';

/// One record of a table or a load file: column name -> JSON-able value.
typedef Row = Map<String, Object?>;

/// The release schema version (`meta.schema_version`, manifest).
const schemaVersion = 1;

/// The load files, in the fixed order used for the content hash.
const loadFileNames = [
  'foods',
  'dishes',
  'names',
  'servings',
  'yields',
  'exercises',
  'cities',
];

const _coreKeys = ['kcal', 'protein', 'carbs', 'fat', 'fiber'];

/// Everything a catalog release holds, as plain records (A05 D5, D6). The pack
/// and the load files are both written from these, so they cannot differ.
class Release {
  const new({
    required this.includesDrafts,
    required this.tables,
    required this.released,
    required this.sanity,
    required this.attribution,
  });

  final bool includesDrafts;

  /// Rows per load file name (`foods`, `dishes`, ...), each sorted.
  final Map<String, List<Row>> tables;

  /// Released IDs (reviewed items only, never drafts) -> lock kind.
  final Map<String, String> released;

  /// Sanity level per food ID (`ok`, `warn`, `waived`) and its deviation.
  final Map<String, ({String level, double deviation})> sanity;

  /// Entries for `meta.attribution`.
  final List<Object?> attribution;

  List<Row> table(String name) => tables[name] ?? const [];

  int count(String name) => table(name).length;

  /// Foods of one kind (`basic` or `variant`).
  int countFoods(String kind) =>
      table('foods').where((r) => r['kind'] == kind).length;
}

/// Builds the [Release] from validated data. [versionOf] gives the
/// `catalog_version` an ID first appeared in.
Release composeRelease({
  required CatalogData data,
  required ValidationReport report,
  required int Function(String id) versionOf,
  required List<Object?> attribution,
  bool includeDrafts = false,
  SanityCheck sanityCheck = const SanityCheck(),
}) {
  final dishes = [
    for (final d in data.dishes)
      if (includeDrafts || !d.isDraft) d,
  ]..sort((a, b) => a.id.compareTo(b.id));
  final basics = [...data.basics]..sort((a, b) => a.id.compareTo(b.id));

  final foods = <Row>[];
  final dishRows = <Row>[];
  final names = <Row>[];
  final released = <String, String>{};
  final sanity = <String, ({String level, double deviation})>{};
  // food id -> unit -> row; later passes replace earlier ones.
  final servings = <String, Map<String, Row>>{};

  String levelOf(String id, Nutrients values, String? override) {
    final r = sanityCheck.check(values, NutrientBasis.per100g);
    final level = switch (r.level) {
      SanityLevel.ok => 'ok',
      SanityLevel.warn => 'warn',
      SanityLevel.fail => 'waived',
    };
    sanity[id] = (level: level, deviation: r.deviation);
    return level;
  }

  void addNames(String target, Names byLang) {
    for (final lang in nameLanguages) {
      final list = byLang[lang] ?? const <String>[];
      for (var i = 0; i < list.length; i++) {
        final key = normalizeKey(list[i]);
        if (key.isEmpty) continue;
        names.add({
          'target_id': target,
          'lang': lang,
          'name': list[i],
          'key': key,
          'is_display': i == 0 ? 1 : 0,
        });
      }
    }
  }

  void putServing(String food, String unit, Row row) {
    (servings[food] ??= {})[unit] = {
      'food_id': food,
      'unit_code': unit,
      ...row,
    };
  }

  Row nutrientColumns(Nutrients n, {Nutrients? low, Nutrients? high}) {
    final row = <String, Object?>{};
    List<double> v(Nutrients x) => [x.kcal, x.protein, x.carbs, x.fat, x.fiber];
    final typ = v(n);
    for (var i = 0; i < _coreKeys.length; i++) {
      row[i == 0 ? 'kcal' : '${_coreKeys[i]}_g'] = typ[i];
    }
    for (final (suffix, x) in [('low', low), ('high', high)]) {
      for (var i = 0; i < _coreKeys.length; i++) {
        row['${_coreKeys[i]}_$suffix'] = x == null ? null : v(x)[i];
      }
    }
    return row;
  }

  Map<String, double>? extrasOf(Nutrients n) => n.extras.isEmpty
      ? null
      : {
          for (final e
              in n.extras.entries.toList()
                ..sort((a, b) => a.key.code.compareTo(b.key.code)))
            e.key.code: e.value,
        };

  String? first(Names n, String lang) =>
      (n[lang] ?? const []).isEmpty ? null : n[lang]!.first;

  for (final b in basics) {
    final n = b.nutrients!.rounded();
    foods.add({
      'id': b.id,
      'kind': 'basic',
      'source': 'usda',
      'source_ref': b.fdcId == null ? null : 'fdc:${b.fdcId}',
      'dish_id': null,
      'name_en': first(b.names, 'en'),
      'name_ar': first(b.names, 'ar'),
      'state': b.state.code,
      'basis': 'per_100g',
      ...nutrientColumns(n),
      'extras': extrasOf(n),
      'density_g_per_ml': null,
      'yield_group': b.yieldGroup,
      'verified': 1,
      'review_status': 'reviewed',
      'sanity': levelOf(b.id, n, b.sanityOverrideReason),
      'catalog_version': versionOf(b.id),
    });
    released[b.id] = 'food';
    addNames(b.id, b.names);
    for (final s in b.servings.entries) {
      putServing(b.id, s.key, {
        'g': s.value,
        'ml': null,
        'range_lo': null,
        'range_hi': null,
        'source': 'usda',
      });
    }
  }

  final variantIds = <String, List<String>>{};
  for (final d in dishes) {
    final reviewed = !d.isDraft;
    final defaultVariant = d.defaultVariant;
    final ids = [for (final v in d.variants) d.variantId(v)];
    variantIds[d.id] = ids;
    dishRows.add({
      'id': d.id,
      'name_en': first(d.names, 'en'),
      'name_ar': first(d.names, 'ar'),
      'default_variant_id': defaultVariant == null
          ? null
          : d.variantId(defaultVariant),
      'review_status': d.review.status,
      'time_min': d.timeMin,
      'catalog_version': versionOf(d.id),
      'variants': [
        for (final v in d.variants)
          {
            'id': d.variantId(v),
            'recipe': v.recipe == null
                ? null
                : [
                    for (final i in v.recipe!)
                      {
                        'food': i.food,
                        'grams': i.grams,
                        'range_lo': i.range?.lo,
                        'range_hi': i.range?.hi,
                      },
                  ],
            'cooked_total_g': v.cookedTotalG,
            'cooked_total_range_lo': v.cookedTotalRange?.lo,
            'cooked_total_range_hi': v.cookedTotalRange?.hi,
            'nutrient_source': v.nutrientSource,
          },
      ],
      'portions': {
        for (final e in d.portions.entries)
          e.key: {
            'g': e.value.g,
            'range_lo': e.value.range.lo,
            'range_hi': e.value.range.hi,
          },
      },
      'review': {
        'status': d.review.status,
        'reviewed_by': d.review.reviewedBy,
        'sources': d.review.sources,
        'notes': d.review.notes,
      },
    });
    if (reviewed) {
      released[d.id] = 'dish';
      for (final id in ids) {
        released[id] = 'variant';
      }
    }
    addNames(d.id, d.names);
    for (final v in d.variants) {
      final id = d.variantId(v);
      final c = report.computed[id]!;
      final typical = c.typical.rounded();
      foods.add({
        'id': id,
        'kind': 'variant',
        'source': 'reference',
        'source_ref': v.nutrientSource,
        'dish_id': d.id,
        'name_en': first(v.names, 'en') ?? first(d.names, 'en'),
        'name_ar': first(v.names, 'ar') ?? first(d.names, 'ar'),
        'state': d.state.code,
        'basis': 'per_100g',
        ...nutrientColumns(
          typical,
          low: c.low.rounded(),
          high: c.high.rounded(),
        ),
        'extras': extrasOf(typical),
        'density_g_per_ml': null,
        'yield_group': null,
        'verified': reviewed ? 1 : 0,
        'review_status': d.review.status,
        'sanity': levelOf(id, typical, v.sanityOverrideReason),
        'catalog_version': versionOf(id),
      });
      addNames(id, v.names);
      // Dish portions are stored on every variant (D5); a variant's own
      // portion of the same unit wins.
      for (final e in d.portions.entries) {
        putServing(id, e.key, _portion(e.value, 'dish'));
      }
    }
  }

  // Portion words (FD-003): on a basic, on a variant, or on a dish (applies
  // to all its variants). A variant's own portion beats the dish-level word.
  final words = data.portionWords ?? const [];
  for (final w in words) {
    final targets = variantIds[w.food] ?? [w.food];
    for (final id in targets) {
      if (!foods.any((f) => f['id'] == id)) continue;
      putServing(id, w.unit, {
        'g': w.g,
        'ml': w.ml,
        'range_lo': w.range?.lo,
        'range_hi': w.range?.hi,
        'source': w.source,
      });
    }
  }
  for (final d in dishes) {
    for (final v in d.variants) {
      for (final e in v.portions.entries) {
        putServing(d.variantId(v), e.key, _portion(e.value, 'variant'));
      }
    }
  }
  for (final w in words) {
    if (variantIds.containsKey(w.food)) continue;
    if (!w.food.contains('/')) continue;
    if (!foods.any((f) => f['id'] == w.food)) continue;
    putServing(w.food, w.unit, {
      'g': w.g,
      'ml': w.ml,
      'range_lo': w.range?.lo,
      'range_hi': w.range?.hi,
      'source': w.source,
    });
  }

  final foodIds = servings.keys.toList()..sort();
  final yields = [...?data.yields]
    ..sort((a, b) {
      final g = a.group.compareTo(b.group);
      if (g != 0) return g;
      final f = a.from.code.compareTo(b.from.code);
      return f != 0 ? f : a.to.code.compareTo(b.to.code);
    });

  final exercises = [...data.exercises]..sort((a, b) => a.id.compareTo(b.id));
  final cities = [...data.cities]..sort((a, b) => a.id.compareTo(b.id));
  for (final e in exercises) {
    released[e.id] = 'exercise';
    addNames(e.id, {'en': e.names});
  }
  for (final c in cities) {
    released[c.id] = 'city';
  }

  return Release(
    includesDrafts: includeDrafts,
    released: released,
    sanity: sanity,
    attribution: attribution,
    tables: {
      'foods': foods,
      'dishes': dishRows,
      'names': names,
      'servings': [
        for (final f in foodIds)
          for (final u in servings[f]!.keys.toList()..sort()) servings[f]![u]!,
      ],
      'yields': [
        for (final y in yields)
          {
            'yield_group': y.group,
            'from_state': y.from.code,
            'to_state': y.to.code,
            'factor': y.factor,
            'source': y.source,
          },
      ],
      'exercises': [
        for (final e in exercises)
          {
            'id': e.id,
            'name_en': e.names.first,
            'type': e.type,
            'equipment': e.equipment,
            'primary_muscle': e.primaryMuscle,
            'catalog_version': versionOf(e.id),
          },
      ],
      'cities': [for (final c in cities) c.toRow()],
    },
  );
}

Row _portion(Portion p, String source) => {
  'g': p.g,
  'ml': null,
  'range_lo': p.range.lo,
  'range_hi': p.range.hi,
  'source': source,
};
