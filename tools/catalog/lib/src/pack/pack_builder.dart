import 'dart:convert';
import 'dart:io';

import 'package:fb_catalog/src/load/load_catalog.dart';
import 'package:fb_catalog/src/release/release.dart';
import 'package:fb_catalog/src/validate/report.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' hide Row;

/// The data is not fit to build a pack from.
class PackException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What `buildPack` wrote.
class PackSummary {
  const new({
    required this.basics,
    required this.dishes,
    required this.variants,
    required this.skippedDrafts,
    required this.names,
    required this.bytes,
  });

  final int basics;
  final int dishes;
  final int variants;
  final int skippedDrafts;
  final int names;
  final int bytes;
}

/// Builds a pack straight from validated data with every row at catalog
/// version 0 (no lock). For tests and quick looks; the release build is
/// `runBuild`.
PackSummary buildPack({
  required CatalogData data,
  required ValidationReport report,
  required String out,
  bool includeDrafts = false,
}) {
  final errors = [...data.issues, ...report.errors];
  if (errors.isNotEmpty) {
    throw PackException(
      'cannot build: ${errors.length} validation error(s), first: '
      '${errors.first}',
    );
  }
  final release = composeRelease(
    data: data,
    report: report,
    versionOf: (_) => 0,
    attribution: const [],
    includeDrafts: includeDrafts,
  );
  writePack(
    release,
    out,
    meta: {
      'schema_version': '$schemaVersion',
      'catalog_version': '0',
      'content_sha256': '',
      'includes_drafts': includeDrafts ? '1' : '0',
      'attribution': '[]',
    },
  );
  return PackSummary(
    basics: release.countFoods('basic'),
    dishes: release.count('dishes'),
    variants: release.countFoods('variant'),
    skippedDrafts: data.dishes.length - release.count('dishes'),
    names: release.count('names'),
    bytes: File(out).lengthSync(),
  );
}

Object? _cell(Row row, String column) => switch (column) {
  'extras_json' => switch (row['extras']) {
    null => null,
    final extras => jsonEncode(extras),
  },
  'secondary_muscles' => (row[column]! as List<Object?>).join(','),
  _ => row[column],
};

/// Columns inserted per table, in DDL order. A column named `extras_json`
/// takes the row's `extras` map as JSON text; `secondary_muscles` takes the
/// row's list as comma-joined codes (`''` for none, A37 D4).
const packColumns = <String, List<String>>{
  'foods': [
    'id', 'kind', 'source', 'source_ref', 'dish_id', 'name_en', 'name_ar',
    'state', 'basis', 'kcal', 'protein_g', 'carbs_g', 'fat_g', 'fiber_g',
    'kcal_low', 'kcal_high', 'protein_low', 'protein_high', 'carbs_low',
    'carbs_high', 'fat_low', 'fat_high', 'fiber_low', 'fiber_high',
    'extras_json', 'density_g_per_ml', 'yield_group', 'verified',
    'review_status', 'sanity', 'catalog_version', //
  ],
  'dishes': [
    'id', 'name_en', 'name_ar', 'default_variant_id', 'review_status',
    'time_min', 'catalog_version', //
  ],
  'names': ['target_id', 'lang', 'name', 'key', 'is_display'],
  'servings': [
    'food_id', 'unit_code', 'g', 'ml', 'range_lo', 'range_hi', 'source', //
  ],
  'yields': ['yield_group', 'from_state', 'to_state', 'factor', 'source'],
  'exercises': [
    'id',
    'name_en',
    'type',
    'equipment',
    'primary_muscle',
    'secondary_muscles',
    'catalog_version', //
  ],
  'cities': [
    'id', 'name_en', 'name_ar', 'country_code', 'admin1', 'lat', 'lon',
    'timezone', 'population', //
  ],
};

/// Writes [release] as a read-only-ready SQLite pack at [out] (A05 D5),
/// replacing any old file. Insert order is fixed, so equal data gives equal
/// bytes.
void writePack(
  Release release,
  String out, {
  required Map<String, String> meta,
}) {
  final outFile = File(out);
  outFile.parent.createSync(recursive: true);
  if (outFile.existsSync()) outFile.deleteSync();
  final db = sqlite3.open(out);
  try {
    db
      ..execute('PRAGMA page_size = 4096')
      ..execute('PRAGMA journal_mode = OFF')
      ..execute(packDdl)
      ..execute('BEGIN');
    for (final MapEntry(key: table, value: columns) in packColumns.entries) {
      final insert = db.prepare(
        'INSERT INTO $table (${columns.join(', ')}) '
        'VALUES (${List.filled(columns.length, '?').join(', ')})',
      );
      for (final row in release.table(table)) {
        insert.execute([for (final c in columns) _cell(row, c)]);
      }
      insert.close();
    }
    db.execute(
      'INSERT INTO names_fts (rowid, key) SELECT rowid, key FROM names',
    );
    final addMeta = db.prepare('INSERT INTO meta VALUES (?, ?)');
    for (final e
        in meta.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      addMeta.execute([e.key, e.value]);
    }
    addMeta.close();
    db
      ..execute('COMMIT')
      ..execute('PRAGMA user_version = $schemaVersion')
      ..execute('VACUUM');
  } finally {
    db.close();
  }
}

/// The pack schema v1 (A05 D5). A05b supplies exercises and cities;
/// `barcodes` stays empty until FD-030.
const packDdl = '''
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL) WITHOUT ROWID;
CREATE TABLE foods (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  source TEXT NOT NULL,
  source_ref TEXT,
  dish_id TEXT,
  name_en TEXT NOT NULL,
  name_ar TEXT,
  state TEXT NOT NULL,
  basis TEXT NOT NULL,
  kcal REAL NOT NULL,
  protein_g REAL NOT NULL,
  carbs_g REAL NOT NULL,
  fat_g REAL NOT NULL,
  fiber_g REAL NOT NULL,
  kcal_low REAL, kcal_high REAL,
  protein_low REAL, protein_high REAL,
  carbs_low REAL, carbs_high REAL,
  fat_low REAL, fat_high REAL,
  fiber_low REAL, fiber_high REAL,
  extras_json TEXT,
  density_g_per_ml REAL,
  yield_group TEXT,
  verified INTEGER NOT NULL,
  review_status TEXT NOT NULL,
  sanity TEXT NOT NULL,
  catalog_version INTEGER NOT NULL
) WITHOUT ROWID;
CREATE INDEX foods_dish ON foods (dish_id);
CREATE TABLE dishes (
  id TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_ar TEXT,
  default_variant_id TEXT,
  review_status TEXT NOT NULL,
  time_min REAL,
  catalog_version INTEGER NOT NULL
) WITHOUT ROWID;
CREATE TABLE names (
  target_id TEXT NOT NULL,
  lang TEXT NOT NULL,
  name TEXT NOT NULL,
  key TEXT NOT NULL,
  is_display INTEGER NOT NULL
);
CREATE INDEX names_key ON names (key);
CREATE INDEX names_target ON names (target_id);
CREATE TABLE servings (
  food_id TEXT NOT NULL,
  unit_code TEXT NOT NULL,
  g REAL,
  ml REAL,
  range_lo REAL,
  range_hi REAL,
  source TEXT NOT NULL,
  PRIMARY KEY (food_id, unit_code)
) WITHOUT ROWID;
CREATE TABLE yields (
  yield_group TEXT NOT NULL,
  from_state TEXT NOT NULL,
  to_state TEXT NOT NULL,
  factor REAL NOT NULL,
  source TEXT NOT NULL,
  PRIMARY KEY (yield_group, from_state, to_state)
) WITHOUT ROWID;
CREATE TABLE barcodes (
  code TEXT PRIMARY KEY,
  food_id TEXT NOT NULL
) WITHOUT ROWID;
CREATE TABLE exercises (
  id TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  type TEXT NOT NULL,
  equipment TEXT NOT NULL,
  primary_muscle TEXT NOT NULL,
  secondary_muscles TEXT NOT NULL,
  catalog_version INTEGER NOT NULL
) WITHOUT ROWID;
CREATE TABLE cities (
  id TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_ar TEXT,
  country_code TEXT NOT NULL,
  admin1 TEXT,
  lat REAL NOT NULL,
  lon REAL NOT NULL,
  timezone TEXT NOT NULL,
  population INTEGER
) WITHOUT ROWID;
CREATE VIRTUAL TABLE names_fts USING fts5(
  key, content='names', content_rowid='rowid', tokenize='trigram'
);
''';

/// Where `build` writes by default; under `build/`, which is gitignored.
String defaultPackPath(String root) =>
    p.join(root, 'build', 'catalog', 'catalog.db');
