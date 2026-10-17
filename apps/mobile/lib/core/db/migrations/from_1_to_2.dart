import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Schema v1 → v2 (A01 D15): the settings store, `settings_kv`, and its
/// outbox triggers.
///
/// Shipped migrations are frozen: never edit this file once it is on `main`
/// (`tools/scripts/check-frozen-migrations.sh`). A later change is a new
/// version with its own `from_<n>_to_<n+1>.dart`.
Future<void> from1To2(Migrator m, Schema2 schema) async {
  await m.createTable(schema.settingsKv);
  await m.createTrigger(schema.settingsKvOutboxAi);
  await m.createTrigger(schema.settingsKvOutboxAu);
  await m.createTrigger(schema.settingsKvNoDelete);
}
