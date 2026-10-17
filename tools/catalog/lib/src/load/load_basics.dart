import 'dart:convert';
import 'dart:io';

import 'package:fb_catalog/src/load/schema.dart';
import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/model/issue.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:json_schema/json_schema.dart';

/// Extract keys of the optional nutrients (see `nutrientFields`).
const Map<String, NutrientKey> _extraKeys = {
  'sugar_g': NutrientKey.sugar,
  'saturated_fat_g': NutrientKey.saturatedFat,
  'trans_fat_g': NutrientKey.transFat,
  'sodium_mg': NutrientKey.sodium,
  'cholesterol_mg': NutrientKey.cholesterol,
  'alcohol_g': NutrientKey.alcohol,
};

/// Per-100 g values by catalog ID, read from `extract.jsonl`.
Map<String, Nutrients> loadExtract(File file, List<CatalogIssue> issues) {
  final result = <String, Nutrients>{};
  var lineNo = 0;
  for (final line in file.readAsLinesSync()) {
    lineNo++;
    if (line.trim().isEmpty) continue;
    try {
      final m = jsonDecode(line) as Map<String, dynamic>;
      final n = m['nutrients'] as Map<String, dynamic>;
      double v(String key) => (n[key] as num).toDouble();
      result[m['id'] as String] = Nutrients(
        kcal: v('kcal'),
        protein: v('protein_g'),
        carbs: v('carbs_g'),
        fat: v('fat_g'),
        fiber: v('fiber_g'),
        extras: {
          for (final e in _extraKeys.entries)
            if (n[e.key] case final num x) e.value: x.toDouble(),
        },
      );
    } on Object catch (e) {
      issues.add(
        CatalogIssue(file.path, 'line $lineNo', 'bad extract line: $e'),
      );
    }
  }
  return result;
}

/// Reads the selection (schema-checked) and joins it with the [extract].
List<BasicFood> loadBasics(
  File selection,
  JsonSchema schema,
  Map<String, Nutrients> extract,
  List<CatalogIssue> issues,
) {
  final data = readChecked(selection, schema, issues);
  if (data == null) return const [];
  final foods = (data as Map<String, dynamic>)['foods'] as List<dynamic>;
  return [
    for (var i = 0; i < foods.length; i++)
      _basic(selection.path, i, foods[i] as Map<String, dynamic>, extract),
  ];
}

BasicFood _basic(
  String file,
  int index,
  Map<String, dynamic> m,
  Map<String, Nutrients> extract,
) {
  final names = m['names'] as Map<String, dynamic>;
  final id = m['id'] as String;
  return BasicFood(
    file: file,
    index: index,
    id: id,
    names: {
      for (final e in names.entries)
        e.key: [for (final n in e.value as List<dynamic>) '$n'],
    },
    state: FoodState.fromCode(m['state'] as String)!,
    nutrients: extract[id],
    sanityOverrideReason:
        (m['sanity_override'] as Map<String, dynamic>?)?['reason'] as String?,
  );
}
