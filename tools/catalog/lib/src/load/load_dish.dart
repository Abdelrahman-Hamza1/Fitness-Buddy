import 'dart:io';

import 'package:fb_catalog/src/load/schema.dart';
import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/model/issue.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:json_schema/json_schema.dart';

/// A dish file read: the dish when the schema accepted it, else the issues.
class LoadedDish {
  const new(this.dish, this.issues);

  final ReferenceDish? dish;
  final List<CatalogIssue> issues;
}

/// Reads one dish YAML and checks it against the v1 [schema]. Semantic rules
/// (references, ranges, sanity, names) are in `validateCatalog`.
LoadedDish loadDish(File file, JsonSchema schema) {
  final issues = <CatalogIssue>[];
  final data = readChecked(file, schema, issues);
  if (data == null) return LoadedDish(null, issues);
  return LoadedDish(_dish(file.path, data as Map<String, dynamic>), issues);
}

ReferenceDish _dish(String file, Map<String, dynamic> m) {
  final review = m['review'] as Map<String, dynamic>;
  return ReferenceDish(
    file: file,
    id: m['id'] as String,
    names: _names(m['names']),
    state: FoodState.fromCode(m['state'] as String)!,
    variants: [
      for (final v in m['variants'] as List<dynamic>)
        _variant(v as Map<String, dynamic>),
    ],
    portions: _portions(m['portions']),
    review: Review(
      status: review['status'] as String,
      reviewedBy: review['reviewed_by'] as String,
      sources: [for (final s in review['sources'] as List<dynamic>) '$s'],
      notes: (review['notes'] as String?) ?? '',
    ),
    sanityOverrideReason: _reason(m['sanity_override']),
    timeMin: (m['time_min'] as num?)?.toDouble(),
  );
}

Variant _variant(Map<String, dynamic> m) => Variant(
  slug: m['id'] as String,
  isDefault: m['default'] as bool,
  names: _names(m['names']),
  portions: _portions(m['portions']),
  recipe: m['recipe'] == null
      ? null
      : [
          for (final r in m['recipe'] as List<dynamic>)
            RecipeItem(
              food: (r as Map<String, dynamic>)['food'] as String,
              grams: (r['grams'] as num).toDouble(),
              range: _range(r['range']),
            ),
        ],
  cookedTotalG: (m['cooked_total_g'] as num?)?.toDouble(),
  cookedTotalRange: _range(m['cooked_total_range']),
  per100g: m['per_100g'] == null
      ? null
      : _per100g(m['per_100g'] as Map<String, dynamic>),
  nutrientSource: m['nutrient_source'] as String?,
  sanityOverrideReason: _reason(m['sanity_override']),
);

Nutrients _per100g(Map<String, dynamic> m) {
  final extras = (m['extras'] as Map<String, dynamic>?) ?? const {};
  return Nutrients(
    kcal: (m['kcal'] as num).toDouble(),
    protein: (m['protein'] as num).toDouble(),
    carbs: (m['carbs'] as num).toDouble(),
    fat: (m['fat'] as num).toDouble(),
    fiber: (m['fiber'] as num).toDouble(),
    extras: {
      for (final e in extras.entries)
        NutrientKey.fromCode(e.key)!: (e.value as num).toDouble(),
    },
  );
}

Names _names(Object? raw) => {
  if (raw != null)
    for (final e in (raw as Map<String, dynamic>).entries)
      e.key: [for (final n in e.value as List<dynamic>) '$n'],
};

Map<String, Portion> _portions(Object? raw) => {
  if (raw != null)
    for (final e in (raw as Map<String, dynamic>).entries)
      e.key: _portion(e.value as Map<String, dynamic>),
};

Range? _range(Object? raw) {
  if (raw == null) return null;
  final pair = raw as List<dynamic>;
  return Range((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
}

String? _reason(Object? raw) =>
    raw == null ? null : (raw as Map<String, dynamic>)['reason'] as String;

Portion _portion(Map<String, dynamic> m) =>
    Portion(g: (m['g'] as num).toDouble(), range: _range(m['range'])!);
