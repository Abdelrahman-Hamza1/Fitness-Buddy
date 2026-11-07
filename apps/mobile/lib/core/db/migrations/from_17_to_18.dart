import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// What Buddy remembers (A67 D10, `06` §6.2): the synced `memory_items`
/// table and its three sync triggers. A new table holds no rows, so nothing
/// is backfilled and no outbox row is written.
///
/// Shipped migrations are frozen: never edit this file once it is on `main`
/// (`tools/scripts/check-frozen-migrations.sh`).
Future<void> from17To18(Migrator m, Schema18 schema) async {
  await m.createTable(schema.memoryItems);
  for (final trigger in [
    schema.memoryItemsOutboxAi,
    schema.memoryItemsOutboxAu,
    schema.memoryItemsNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
}
