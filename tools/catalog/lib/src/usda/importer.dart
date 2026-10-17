import 'dart:convert';
import 'dart:io';

import 'package:fb_catalog/src/usda/csv_reader.dart';
import 'package:fb_catalog/src/usda/nutrient_mapping.dart';
import 'package:fb_catalog/src/usda/selection.dart';
import 'package:path/path.dart' as p;

/// The import cannot produce a trustworthy extract; the message says why and
/// names the FDC food or nutrient id.
class ImportException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A portion from `food_portion.csv`: [amount] of [label] weighs [grams].
class UsdaPortion {
  const new(this.amount, this.label, this.grams);

  final double amount;
  final String label;
  final double grams;

  Map<String, Object> toJson() => {
    'amount': amount,
    'g': grams,
    'label': label,
  };
}

/// One imported basic, ready to write as a line of `extract.jsonl`.
class UsdaFood {
  const new({
    required this.id,
    required this.fdcId,
    required this.dataset,
    required this.description,
    required this.nutrients,
    required this.portions,
    required this.energyNutrientId,
    required this.carbsNutrientId,
    required this.fiberZero,
  });

  final String id;
  final int fdcId;

  /// Directory name of the dataset the food came from (`sr_legacy`,
  /// `foundation`).
  final String dataset;

  /// USDA's own description, kept as the `source_ref` text.
  final String description;

  /// Values per 100 g, keyed as in [nutrientFields]; extras only when present.
  final Map<String, double> nutrients;
  final List<UsdaPortion> portions;

  /// Which FDC nutrient supplied kcal (1008, 2048 or 2047) and carbs (1005 or
  /// 1050): recorded so a reviewer sees which fallback applied.
  final int energyNutrientId;
  final int carbsNutrientId;

  /// Fiber was absent in USDA and stored as 0 because the selection said so.
  final bool fiberZero;

  /// Keys in a fixed order, so the output is byte-for-byte reproducible.
  Map<String, Object> toJson() => {
    'id': id,
    'fdc_id': fdcId,
    'dataset': dataset,
    'description': description,
    'nutrients': {
      for (final f in nutrientFields)
        if (nutrients.containsKey(f.key)) f.key: nutrients[f.key]!,
    },
    'energy_nutrient': energyNutrientId,
    'carbs_nutrient': carbsNutrientId,
    if (fiberZero) 'fiber_zero': true,
    'portions': [for (final portion in portions) portion.toJson()],
  };
}

/// Imports [selection] from the unpacked FDC CSV datasets. [datasetDirs] maps
/// a dataset name (`sr_legacy`, `foundation`) to the directory holding its
/// `food.csv`, `food_nutrient.csv`, `food_portion.csv`, `measure_unit.csv` and
/// `nutrient.csv`. Returns the foods sorted by catalog ID.
///
/// Streams every CSV file. Fails with an [ImportException] when a food is
/// missing or in two datasets, a nutrient id is unknown to `nutrient.csv` or
/// has a different unit than expected, or a core nutrient is missing (fiber
/// excepted when the entry says `fiber_zero`).
Future<List<UsdaFood>> importUsda({
  required Map<String, Directory> datasetDirs,
  required List<SelectionEntry> selection,
}) async {
  final byFdcId = {for (final e in selection) e.fdcId: e};
  final descriptions = <int, String>{};
  final datasetOf = <int, String>{};

  final nutrientUnits = <String, Map<int, String>>{};
  for (final MapEntry(key: name, value: dir) in datasetDirs.entries) {
    final units = await _readNutrientUnits(dir);
    _checkMapping(name, units);
    nutrientUnits[name] = units;
    await for (final row in readCsvFile(File(p.join(dir.path, 'food.csv')))) {
      final id = int.tryParse(row['fdc_id']!);
      if (id == null || !byFdcId.containsKey(id)) continue;
      if (datasetOf.containsKey(id)) {
        throw ImportException(
          'FDC $id (${byFdcId[id]!.id}) is in both ${datasetOf[id]} and $name',
        );
      }
      datasetOf[id] = name;
      descriptions[id] = row['description']!;
    }
  }
  for (final e in selection) {
    if (!datasetOf.containsKey(e.fdcId)) {
      throw ImportException(
        'FDC ${e.fdcId} (${e.id}) is in none of: '
        '${datasetDirs.keys.join(', ')}',
      );
    }
  }

  final foods = <UsdaFood>[];
  for (final MapEntry(key: name, value: dir) in datasetDirs.entries) {
    final ids = {
      for (final e in datasetOf.entries)
        if (e.value == name) e.key,
    };
    if (ids.isEmpty) continue;
    final amounts = await _readAmounts(dir, ids, nutrientUnits[name]!);
    final portions = await _readPortions(dir, ids);
    for (final fdcId in ids) {
      foods.add(
        _build(
          byFdcId[fdcId]!,
          name,
          descriptions[fdcId]!,
          amounts[fdcId] ?? const {},
          portions[fdcId] ?? const [],
        ),
      );
    }
  }
  foods.sort((a, b) => a.id.compareTo(b.id));
  return foods;
}

/// The extract file content: one JSON object per line, sorted by catalog ID,
/// `\n` line ends, a final newline. Same input, same bytes.
String encodeExtract(List<UsdaFood> foods) {
  final sorted = [...foods]..sort((a, b) => a.id.compareTo(b.id));
  final buffer = StringBuffer();
  for (final food in sorted) {
    buffer
      ..write(jsonEncode(food.toJson()))
      ..write('\n');
  }
  return buffer.toString();
}

Future<Map<int, String>> _readNutrientUnits(Directory dir) async {
  final units = <int, String>{};
  await for (final row in readCsvFile(File(p.join(dir.path, 'nutrient.csv')))) {
    final id = int.tryParse(row['id']!);
    if (id != null) units[id] = row['unit_name']!;
  }
  return units;
}

/// Every id in the mapping must exist in `nutrient.csv` with the unit we
/// assume, so a renamed or re-united nutrient fails here and not silently.
void _checkMapping(String dataset, Map<int, String> units) {
  for (final field in nutrientFields) {
    for (final source in field.sources) {
      final unit = units[source.id];
      if (unit == null) {
        throw ImportException(
          '$dataset: nutrient id ${source.id} (${field.key}) is not in '
          'nutrient.csv',
        );
      }
      if (unit.toUpperCase() != source.unit) {
        throw ImportException(
          '$dataset: nutrient id ${source.id} (${field.key}) has unit $unit, '
          'expected ${source.unit}',
        );
      }
    }
  }
}

/// fdc_id -> nutrient id -> amount per 100 g, for the selected foods only. A
/// nutrient id missing from `nutrient.csv` fails the import.
Future<Map<int, Map<int, double>>> _readAmounts(
  Directory dir,
  Set<int> ids,
  Map<int, String> known,
) async {
  final result = <int, Map<int, double>>{};
  await for (final row in readCsvFile(
    File(p.join(dir.path, 'food_nutrient.csv')),
  )) {
    final fdcId = int.tryParse(row['fdc_id']!);
    if (fdcId == null || !ids.contains(fdcId)) continue;
    final nutrientId = int.tryParse(row['nutrient_id']!);
    if (nutrientId == null || !known.containsKey(nutrientId)) {
      throw ImportException(
        'FDC $fdcId: unknown nutrient id `${row['nutrient_id']}` '
        '(not in nutrient.csv)',
      );
    }
    final amount = double.tryParse(row['amount']!);
    if (amount == null) continue; // empty amount: treat as absent
    final perFood = result.putIfAbsent(fdcId, () => {});
    if (perFood.containsKey(nutrientId)) {
      throw ImportException(
        'FDC $fdcId: nutrient id $nutrientId appears twice in '
        'food_nutrient.csv',
      );
    }
    perFood[nutrientId] = amount;
  }
  return result;
}

Future<Map<int, List<UsdaPortion>>> _readPortions(
  Directory dir,
  Set<int> ids,
) async {
  final unitNames = <String, String>{};
  final unitFile = File(p.join(dir.path, 'measure_unit.csv'));
  if (unitFile.existsSync()) {
    await for (final row in readCsvFile(unitFile)) {
      unitNames[row['id']!] = row['name']!;
    }
  }
  final result = <int, List<UsdaPortion>>{};
  await for (final row in readCsvFile(
    File(p.join(dir.path, 'food_portion.csv')),
  )) {
    final fdcId = int.tryParse(row['fdc_id']!);
    if (fdcId == null || !ids.contains(fdcId)) continue;
    final grams = double.tryParse(row['gram_weight']!);
    if (grams == null || grams <= 0) continue;
    final amount = double.tryParse(row['amount']!) ?? 1;
    final unit = unitNames[row['measure_unit_id']] ?? '';
    final label = [
      if (unit.isNotEmpty && unit != 'undetermined') unit,
      row['portion_description']!,
      row['modifier']!,
    ].where((s) => s.isNotEmpty).join(' ');
    result.putIfAbsent(fdcId, () => []).add(UsdaPortion(amount, label, grams));
  }
  for (final list in result.values) {
    list.sort((a, b) {
      final byLabel = a.label.compareTo(b.label);
      if (byLabel != 0) return byLabel;
      final byAmount = a.amount.compareTo(b.amount);
      return byAmount != 0 ? byAmount : a.grams.compareTo(b.grams);
    });
  }
  return result;
}

UsdaFood _build(
  SelectionEntry entry,
  String dataset,
  String description,
  Map<int, double> amounts,
  List<UsdaPortion> portions,
) {
  final values = <String, double>{};
  final used = <String, int>{};
  var fiberZero = false;
  for (final field in nutrientFields) {
    FdcNutrient? hit;
    for (final source in field.sources) {
      if (amounts.containsKey(source.id)) {
        hit = source;
        break;
      }
    }
    if (hit != null) {
      values[field.key] = amounts[hit.id]!;
      used[field.key] = hit.id;
    } else if (field.key == 'fiber_g' && entry.fiberZero) {
      values[field.key] = 0;
      fiberZero = true;
    } else if (field.core) {
      final tried = field.sources.map((s) => s.id).join('/');
      final hint = field.key == 'fiber_g'
          ? ', set fiber_zero: true if USDA omits it'
          : '';
      throw ImportException(
        'FDC ${entry.fdcId} (${entry.id}): missing ${field.key} '
        '(nutrient $tried)'
        '$hint',
      );
    }
  }
  return UsdaFood(
    id: entry.id,
    fdcId: entry.fdcId,
    dataset: dataset,
    description: description,
    nutrients: values,
    portions: portions,
    energyNutrientId: used['kcal']!,
    carbsNutrientId: used['carbs_g']!,
    fiberZero: fiberZero,
  );
}
