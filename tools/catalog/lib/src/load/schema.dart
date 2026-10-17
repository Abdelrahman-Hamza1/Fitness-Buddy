import 'dart:convert';
import 'dart:io';

import 'package:fb_catalog/src/load/yaml_json.dart';
import 'package:fb_catalog/src/model/issue.dart';
import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// File names of the committed schemas in `data/schema/`.
const dishSchemaFile = 'reference_dish.v1.schema.json';
const selectionSchemaFile = 'usda_selection.v1.schema.json';
const yieldsSchemaFile = 'yields.v1.schema.json';
const portionWordsSchemaFile = 'portion_words.v1.schema.json';
const attributionSchemaFile = 'attribution.v1.schema.json';

/// Loads the schema [name] from [schemaDir].
JsonSchema loadSchema(String schemaDir, String name) {
  final file = File(p.join(schemaDir, name));
  if (!file.existsSync()) {
    throw FormatException('missing schema ${file.path}');
  }
  return JsonSchema.create(jsonDecode(file.readAsStringSync()) as Object);
}

/// Parses [file] as YAML and checks it against [schema]. Returns the plain
/// data, or `null` with [issues] filled (file, path, message).
Object? readChecked(File file, JsonSchema schema, List<CatalogIssue> issues) {
  final Object? plain;
  try {
    plain = yamlToPlain(loadYamlNode(file.readAsStringSync()));
  } on YamlException catch (e) {
    final line = e.span?.start.line;
    issues.add(
      CatalogIssue(
        file.path,
        '',
        'not valid YAML${line == null ? '' : ' (line ${line + 1})'}: '
            '${e.message}',
      ),
    );
    return null;
  }
  final result = schema.validate(plain);
  if (result.isValid) return plain;
  final seen = <String>{};
  for (final error in result.errors) {
    final issue = _friendly(file.path, error.instancePath, error.message);
    if (seen.add(issue.toString())) issues.add(issue);
  }
  return null;
}

/// json_schema's own wording is terse; this names the field and the rule.
CatalogIssue _friendly(String file, String path, String message) {
  final missing = RegExp(r'^required prop missing: (\S+) from')
      .firstMatch(message);
  if (missing != null) {
    return CatalogIssue(
      file,
      '${_parent(path, missing[1]!)}/${missing[1]}',
      'required property `${missing[1]}` is missing',
    );
  }
  final extra = RegExp(r'^unallowed additional property (.+)$')
      .firstMatch(message);
  if (extra != null) {
    return CatalogIssue(
      file,
      '${_parent(path, extra[1]!)}/${extra[1]}',
      'unknown property `${extra[1]}` (check the spelling)',
    );
  }
  final pattern = RegExp(
    r'^pattern violated \((.*) vs RegExp: pattern=(.*) flags=\w*\)$',
  ).firstMatch(message);
  if (pattern != null) {
    return CatalogIssue(
      file,
      path,
      'value "${pattern[1]}" does not match the required format ${pattern[2]}',
    );
  }
  final items = RegExp(r'^minItems violated \((\d+) vs (\d+)\)')
      .firstMatch(message);
  if (items != null) {
    return CatalogIssue(
      file,
      path,
      'needs at least ${items[2]} item(s), has ${items[1]}',
    );
  }
  if (message.contains('oneOf') && path.contains('/rows/')) {
    return CatalogIssue(
      file,
      path,
      'a portion word needs `g` or `ml`, and not both',
    );
  }
  if (message.contains('oneOf')) {
    return CatalogIssue(
      file,
      path,
      'a variant needs either `recipe` + `cooked_total_g`, or `per_100g` + '
      '`nutrient_source`, and not both',
    );
  }
  return CatalogIssue(file, path, message);
}

/// The parent path of a property the validator reports on its container
/// (some errors carry the container path, some already the property path).
String _parent(String path, String property) => path.endsWith('/$property')
    ? path.substring(0, path.length - property.length - 1)
    : path;
