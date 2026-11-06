import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Day estimates (A62b D4, D19, DY-006, TD-114): `day_marks.estimate_kcal`
/// (nullable, 1–20,000) and `day_marks.estimate_only` (default false).
/// Every existing mark reads as "no estimate", made by the user marking
/// the day, exactly what the dayMark v1 → v2 sync upgrade gives. Adding a
/// column fires no trigger, so no outbox row is written.
///
/// It also prepares sync for dayMark v2, as 14 → 15 did for the diary
/// entities (A62 D23):
/// - a day mark an older build parked as `unsupported` was sent as schema
///   1 (older builds wrote nothing else), so it is marked
///   `refused_schema = 1`: a possible downgrade the server refused,
///   recovered from the server's row before any retry. Rows already marked
///   keep their mark;
/// - kept local versions (`sync_displaced.row_json`, raw SQL values) of day
///   marks gain `estimate_kcal` null and `estimate_only` 0, so they encode
///   as valid schema 2 (same content, same HLC).
///
/// Shipped migrations are frozen: never edit this file once it is on `main`
/// (`tools/scripts/check-frozen-migrations.sh`).
Future<void> from15To16(Migrator m, Schema16 schema) async {
  await m.addColumn(schema.dayMarks, schema.dayMarks.estimateKcal);
  await m.addColumn(schema.dayMarks, schema.dayMarks.estimateOnly);
  await m.database.customStatement(
    'UPDATE sync_parked SET refused_schema = 1 '
    "WHERE entity = 'dayMark' AND reason = 'unsupported' "
    'AND refused_schema IS NULL',
  );
  await m.database.customStatement(
    'UPDATE sync_displaced SET refused_schema = 1 '
    "WHERE entity = 'dayMark' AND parked_reason = 'unsupported' "
    'AND refused_schema IS NULL',
  );
  await m.database.customStatement(
    'UPDATE sync_displaced SET row_json = '
    r"json_insert(row_json, '$.estimate_kcal', NULL, '$.estimate_only', 0) "
    "WHERE entity = 'dayMark'",
  );
}
