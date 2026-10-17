import 'dart:io';

import 'package:yaml/yaml.dart';

/// Catalog ID rule (A03 D4): `usda:<slug>` for basics.
final _usdaId = RegExp(r'^usda:[a-z0-9]+(_[a-z0-9]+)*$');

/// One line of `data/usda_selection.yaml`: a basic picked from USDA.
class SelectionEntry {
  const new({required this.id, required this.fdcId, this.fiberZero = false});

  /// Catalog ID, `usda:<slug>`.
  final String id;

  /// FoodData Central ID; names the dataset implicitly (A03 D1).
  final int fdcId;

  /// USDA omits fiber for this food (meat, oil, eggs): store 0 instead of
  /// failing the import.
  final bool fiberZero;
}

/// Thrown for a malformed selection file; the message names file and entry.
class SelectionException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads the selection file. Only the fields the importer needs are checked
/// here (names, servings, state, ... are validated by the catalog validator).
List<SelectionEntry> loadSelection(File file) {
  final Object? doc;
  try {
    doc = loadYaml(file.readAsStringSync());
  } on YamlException catch (e) {
    throw SelectionException('${file.path}: $e');
  }
  if (doc is! YamlMap || doc['foods'] is! YamlList) {
    throw SelectionException(
      '${file.path}: expected a top-level `foods:` list',
    );
  }
  final entries = <SelectionEntry>[];
  final ids = <String>{};
  final fdcIds = <int>{};
  var index = 0;
  for (final raw in doc['foods'] as YamlList) {
    index++;
    final where = '${file.path}: foods[$index]';
    if (raw is! YamlMap) throw SelectionException('$where: not a map');
    final id = raw['id'];
    final fdcId = raw['fdc_id'];
    final fiberZero = raw['fiber_zero'] ?? false;
    if (id is! String || !_usdaId.hasMatch(id) || id.length > 64) {
      throw SelectionException('$where: bad id `$id` (want usda:<slug>)');
    }
    if (fdcId is! int) {
      throw SelectionException('$where ($id): fdc_id must be an integer');
    }
    if (fiberZero is! bool) {
      throw SelectionException('$where ($id): fiber_zero must be true/false');
    }
    if (!ids.add(id)) throw SelectionException('$where: duplicate id $id');
    if (!fdcIds.add(fdcId)) {
      throw SelectionException('$where ($id): fdc_id $fdcId used twice');
    }
    entries.add(SelectionEntry(id: id, fdcId: fdcId, fiberZero: fiberZero));
  }
  return entries;
}
