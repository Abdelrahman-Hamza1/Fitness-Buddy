import 'dart:io';

import 'package:fb_catalog/src/load/schema.dart';
import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/model/issue.dart';
import 'package:fb_catalog/src/model/yields.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:json_schema/json_schema.dart';

/// Reads `yields.yaml` (schema-checked). `null` when the file fails the schema
/// (the problems are in [issues]).
List<YieldRow>? loadYields(
  File file,
  JsonSchema schema,
  List<CatalogIssue> issues,
) {
  final data = readChecked(file, schema, issues);
  if (data == null) return null;
  final rows = (data as Map<String, dynamic>)['rows'] as List<dynamic>;
  return [
    for (var i = 0; i < rows.length; i++)
      _yield(file.path, i, rows[i] as Map<String, dynamic>),
  ];
}

YieldRow _yield(String file, int index, Map<String, dynamic> m) => YieldRow(
  file: file,
  index: index,
  group: m['group'] as String,
  from: FoodState.fromCode(m['from'] as String)!,
  to: FoodState.fromCode(m['to'] as String)!,
  factor: (m['factor'] as num).toDouble(),
  source: m['source'] as String,
  note: m['note'] as String?,
);

/// Reads `portion_words.yaml` (schema-checked). `null` when it fails
/// the schema.
List<PortionWordRow>? loadPortionWords(
  File file,
  JsonSchema schema,
  List<CatalogIssue> issues,
) {
  final data = readChecked(file, schema, issues);
  if (data == null) return null;
  final rows = (data as Map<String, dynamic>)['rows'] as List<dynamic>;
  return [
    for (var i = 0; i < rows.length; i++)
      _word(file.path, i, rows[i] as Map<String, dynamic>),
  ];
}

PortionWordRow _word(String file, int index, Map<String, dynamic> m) {
  final range = m['range'] as List<dynamic>?;
  return PortionWordRow(
    file: file,
    index: index,
    food: m['food'] as String,
    unit: m['unit'] as String,
    g: (m['g'] as num?)?.toDouble(),
    ml: (m['ml'] as num?)?.toDouble(),
    range: range == null
        ? null
        : Range((range[0] as num).toDouble(), (range[1] as num).toDouble()),
    source: m['source'] as String,
    note: m['note'] as String?,
  );
}
