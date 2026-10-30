import 'package:sqlite3/sqlite3.dart';

/// The tables and columns every readable pack has (schema v1, A05 D5; the
/// same DDL as `tools/catalog` and `test/fixtures/catalog_fixture.sql`).
/// `OfflineCatalog` reads these columns, so a pack missing one would attach
/// and then fail at query time (A24 fix check #1).
const requiredPackColumns = <String, List<String>>{
  'meta': ['key', 'value'],
  'foods': [
    'id',
    'kind',
    'source',
    'source_ref',
    'dish_id',
    'name_en',
    'name_ar',
    'state',
    'basis',
    'kcal',
    'protein_g',
    'carbs_g',
    'fat_g',
    'fiber_g',
    'kcal_low',
    'kcal_high',
    'protein_low',
    'protein_high',
    'carbs_low',
    'carbs_high',
    'fat_low',
    'fat_high',
    'fiber_low',
    'fiber_high',
    'extras_json',
    'density_g_per_ml',
    'yield_group',
    'verified',
    'review_status',
    'sanity',
    'catalog_version',
  ],
  'dishes': [
    'id',
    'name_en',
    'name_ar',
    'default_variant_id',
    'review_status',
    'time_min',
    'catalog_version',
  ],
  'names': ['target_id', 'lang', 'name', 'key', 'is_display'],
  'names_fts': ['key'],
  'servings': [
    'food_id',
    'unit_code',
    'g',
    'ml',
    'range_lo',
    'range_hi',
    'source',
  ],
  'yields': ['yield_group', 'from_state', 'to_state', 'factor', 'source'],
  'barcodes': ['code', 'food_id'],
  'cities': [
    'id',
    'name_en',
    'name_ar',
    'country_code',
    'admin1',
    'lat',
    'lon',
    'timezone',
    'population',
  ],
  'exercises': [
    'id',
    'name_en',
    'type',
    'equipment',
    'primary_muscle',
    'catalog_version',
  ],
};

/// Checks that the SQLite file at [path] is a catalog pack this app reads,
/// for the published [version] (A24 review #1): integrity, `meta`
/// `schema_version` == [schema] and `catalog_version` == [version], and
/// every [requiredPackColumns] table readable with all its columns. Lives in `core/db/` because it
/// opens a (read-only) connection.
///
/// Returns `null` when valid, else a content-free reason (safe to report:
/// no paths, no user data). Opens the file read-only; never writes.
String? validateCatalogPack(
  String path, {
  required int version,
  required int schema,
}) {
  final Database db;
  try {
    db = sqlite3.open(path, mode: OpenMode.readOnly);
  } on Object {
    return 'not a database';
  }
  try {
    final check = db.select('PRAGMA quick_check');
    if (check.isEmpty || check.first.values.first != 'ok') {
      return 'integrity check failed';
    }
    for (final MapEntry(key: table, value: columns)
        in requiredPackColumns.entries) {
      final present = {
        for (final row in db.select('SELECT name FROM pragma_table_info(?)', [
          table,
        ]))
          row['name'],
      };
      if (!present.containsAll(columns)) return 'missing columns';
      // Reads one row through every column, like the catalog's queries.
      db.select(
        'SELECT ${columns.map((c) => '"$c"').join(', ')} FROM "$table" '
        'LIMIT 1',
      );
    }
    String? meta(String key) {
      final rows = db.select('SELECT value FROM meta WHERE key = ?', [key]);
      return rows.isEmpty ? null : '${rows.first.values.first}';
    }

    if (meta('schema_version') != '$schema') {
      return 'unsupported schema';
    }
    if (meta('catalog_version') != '$version') return 'version mismatch';
    return null;
  } on Object {
    return 'unreadable pack';
  } finally {
    db.close();
  }
}
