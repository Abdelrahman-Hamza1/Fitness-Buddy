import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Buddy's conversation summary (A66 D9, `06` §6.2): the synced
/// `buddy_summaries` table (one row per user) and its three sync triggers,
/// plus `ix_chat_messages_status` for the waiting turns the restorer and the
/// dispatcher read (A66 D12). A new table holds no rows, so nothing is
/// backfilled and no outbox row is written; an index writes no outbox row.
///
/// Shipped migrations are frozen: never edit this file once it is on `main`
/// (`tools/scripts/check-frozen-migrations.sh`).
Future<void> from16To17(Migrator m, Schema17 schema) async {
  await m.createTable(schema.buddySummaries);
  for (final trigger in [
    schema.buddySummariesOutboxAi,
    schema.buddySummariesOutboxAu,
    schema.buddySummariesNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
  await m.createIndex(schema.ixChatMessagesStatus);
}
