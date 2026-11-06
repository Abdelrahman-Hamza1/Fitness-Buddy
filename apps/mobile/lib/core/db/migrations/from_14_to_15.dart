import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Meal estimates (A62a D3, D19, TD-114): `user_estimate` (default 0) and
/// `protein_known`, `carbs_known`, `fat_known`, `fiber_known` (default 1)
/// on `diary_entries` and `saved_meal_items`. Every existing row reads as
/// a fully known non-estimate, exactly what the v1 → v2 sync upgrade
/// gives. Adding a column fires no trigger, so no outbox row is written.
///
/// It also prepares sync for the new schema (A62 D23, review fixes):
/// - `refused_schema` on `sync_parked` and `sync_displaced`. A version of a
///   diary entry or saved-meal item an older build had parked as
///   `unsupported` was sent as schema 1 (older builds wrote nothing else),
///   so it is marked `refused_schema = 1`: a possible downgrade the server
///   refused, recovered from the server's row before any retry.
/// - Kept local versions (`sync_displaced.row_json`, raw SQL values) of
///   those two entities gain the five new columns with the same defaults,
///   so they encode as valid schema 2 (same content, same HLC).
///
/// Shipped migrations are frozen: never edit this file once it is on `main`
/// (`tools/scripts/check-frozen-migrations.sh`).
Future<void> from14To15(Migrator m, Schema15 schema) async {
  await m.addColumn(schema.syncParked, schema.syncParked.refusedSchema);
  await m.addColumn(schema.syncDisplaced, schema.syncDisplaced.refusedSchema);
  const entities = "('diaryEntry', 'savedMealItem')";
  await m.database.customStatement(
    'UPDATE sync_parked SET refused_schema = 1 '
    "WHERE entity IN $entities AND reason = 'unsupported'",
  );
  await m.database.customStatement(
    'UPDATE sync_displaced SET refused_schema = 1 '
    "WHERE entity IN $entities AND parked_reason = 'unsupported'",
  );
  await m.database.customStatement(
    'UPDATE sync_displaced SET row_json = json_insert(row_json, '
    r"'$.user_estimate', 0, '$.protein_known', 1, '$.carbs_known', 1, "
    r"'$.fat_known', 1, '$.fiber_known', 1) "
    'WHERE entity IN $entities',
  );
  for (final (table, columns) in [
    (
      schema.diaryEntries,
      [
        schema.diaryEntries.userEstimate,
        schema.diaryEntries.proteinKnown,
        schema.diaryEntries.carbsKnown,
        schema.diaryEntries.fatKnown,
        schema.diaryEntries.fiberKnown,
      ],
    ),
    (
      schema.savedMealItems,
      [
        schema.savedMealItems.userEstimate,
        schema.savedMealItems.proteinKnown,
        schema.savedMealItems.carbsKnown,
        schema.savedMealItems.fatKnown,
        schema.savedMealItems.fiberKnown,
      ],
    ),
  ]) {
    for (final column in columns) {
      await m.addColumn(table, column);
    }
  }
}
