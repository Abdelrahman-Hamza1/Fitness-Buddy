import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Durable Buddy cards (A23 D4): the synced `proposals` table with its
/// indexes and outbox triggers, and the two local-only `chat_messages`
/// columns (`request_json` for A23b's queue, `answer_json` for offline card
/// rebuilds, TD-102). One migration for A23a and A23b.
Future<void> from8To9(Migrator m, Schema9 schema) async {
  await m.createTable(schema.proposals);
  await m.addColumn(schema.chatMessages, schema.chatMessages.requestJson);
  await m.addColumn(schema.chatMessages, schema.chatMessages.answerJson);
  for (final index in [schema.ixProposalsBudget, schema.ixProposalsPending]) {
    await m.createIndex(index);
  }
  for (final trigger in [
    schema.proposalsOutboxAi,
    schema.proposalsOutboxAu,
    schema.proposalsNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
}
