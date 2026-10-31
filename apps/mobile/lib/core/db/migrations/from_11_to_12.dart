import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Sync's local bookkeeping (A34 D5, D7, fix 1): the parked versions,
/// the deferred documents and the displaced local versions. Local-only
/// tables without triggers; no outbox row.
Future<void> from11To12(Migrator m, Schema12 schema) async {
  await m.createTable(schema.syncParked);
  await m.createTable(schema.syncDeferred);
  await m.createTable(schema.syncDisplaced);
}
