import 'dart:io';

import 'package:fb_catalog/src/load/load_basics.dart';
import 'package:fb_catalog/src/load/load_dish.dart';
import 'package:fb_catalog/src/load/load_yields.dart';
import 'package:fb_catalog/src/load/schema.dart';
import 'package:fb_catalog/src/model/dish.dart';
import 'package:fb_catalog/src/model/issue.dart';
import 'package:fb_catalog/src/model/yields.dart';
import 'package:path/path.dart' as p;

/// Everything read from disk, plus the problems found while reading.
class CatalogData {
  const new(
    this.basics,
    this.dishes,
    this.issues, {
    this.yields,
    this.portionWords,
  });

  final List<BasicFood> basics;
  final List<ReferenceDish> dishes;

  /// Rows of `yields.yaml`; `null` when the file isn't there (yet).
  final List<YieldRow>? yields;

  /// Rows of `portion_words.yaml`; `null` when the file isn't there (yet).
  final List<PortionWordRow>? portionWords;

  /// File, YAML and schema problems. Dishes with such problems are left out.
  final List<CatalogIssue> issues;
}

/// Loads the selection, the extract and every `*.yaml` in [dishesDir] (a
/// missing folder means no dishes yet). [yields] and [portionWords] are
/// optional files: absent means not curated yet.
CatalogData loadCatalog({
  required String schemaDir,
  required File selection,
  required File extract,
  required Directory dishesDir,
  File? yields,
  File? portionWords,
}) {
  final issues = <CatalogIssue>[];
  final basics = loadBasics(
    selection,
    loadSchema(schemaDir, selectionSchemaFile),
    loadExtract(extract, issues),
    issues,
  );
  final dishSchema = loadSchema(schemaDir, dishSchemaFile);
  final dishes = <ReferenceDish>[];
  if (dishesDir.existsSync()) {
    final files =
        dishesDir
            .listSync()
            .whereType<File>()
            .where((f) => p.extension(f.path) == '.yaml')
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final loaded = loadDish(file, dishSchema);
      issues.addAll(loaded.issues);
      if (loaded.dish != null) dishes.add(loaded.dish!);
    }
  }
  return CatalogData(
    basics,
    dishes,
    issues,
    yields: yields != null && yields.existsSync()
        ? loadYields(yields, loadSchema(schemaDir, yieldsSchemaFile), issues)
        : null,
    portionWords: portionWords != null && portionWords.existsSync()
        ? loadPortionWords(
            portionWords,
            loadSchema(schemaDir, portionWordsSchemaFile),
            issues,
          )
        : null,
  );
}
