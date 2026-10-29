import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.steps.dart';

/// Additive chat transcript and outbox capture (A22 D3).
Future<void> from6To7(Migrator m, Schema7 schema) async {
  await m.createTable(schema.chatMessages);
  await m.createIndex(schema.ixChatMessagesOrder);
  await m.createIndex(schema.ixChatMessagesReply);
  for (final trigger in [
    schema.chatMessagesOutboxAi,
    schema.chatMessagesOutboxAu,
    schema.chatMessagesNoDelete,
  ]) {
    await m.createTrigger(trigger);
  }
}
