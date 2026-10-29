import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Additive weigh-in schema and outbox capture (A14 D7, D11). Self-contained
/// so a renumber (D11) only renames it.
Future<void> from5To6(Migrator m, Schema6 schema) async {
  await m.createTable(schema.weighIns);
  await m.createIndex(schema.ixWeighInsLive);
  for (final trigger in [
    schema.weighInsOutboxAi,
    schema.weighInsOutboxAu,
    schema.weighInsNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
}
