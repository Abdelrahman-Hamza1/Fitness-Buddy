import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/chat_tables.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_mappers.dart';

/// Plans `chat_messages` rows inside the applier's transaction (A22 D5).
///
/// Re-checks every wire rule at the boundary and rejects with
/// `InvalidOp(code)`, never truncating: callers sanitize first
/// (`ChatText.sanitize`). A rejection names a code, never the text.
final class ChatMessageOpHandler extends ChangeOpHandler<ChatMessageOp> {
  /// Bound to the applier's database.
  const new(this.db);

  /// Profile database.
  final AppDatabase db;

  @override
  String get family => ChatMessageOp.familyName;

  @override
  Future<OpPlan> plan(
    ChatMessageOp op,
    TxReader tx,
    ApplyContext context,
  ) async => switch (op) {
    CreateChatMessage() => _create(op),
    SetChatMessageStatus() => await _setStatus(op, tx),
  };

  OpPlan _create(CreateChatMessage op) {
    if (op.validate() case final invalid?) {
      throw ChangeRejected(InvalidOp(invalid.code));
    }
    return OpPlan([
      InsertRow(db.chatMessages, chatMessageColumns(op.id, op.draft)),
    ]);
  }

  Future<OpPlan> _setStatus(SetChatMessageStatus op, TxReader tx) async {
    final row = await tx.liveRow(db.chatMessages, op.id);
    if (row == null) {
      throw ChangeRejected(RowNotFound(entity: chatMessageEntity, id: op.id));
    }
    if (row.version != op.expectedVersion) {
      throw ChangeRejected(
        VersionConflict(
          entity: chatMessageEntity,
          id: op.id,
          expected: op.expectedVersion,
          actual: row.version,
        ),
      );
    }
    final language = op.language?.code ?? row.language;
    if (row.status == op.status.code && row.language == language) {
      return OpPlan(const []);
    }
    return OpPlan([
      UpdateRow(
        db.chatMessages,
        op.id,
        ChatMessagesCompanion(
          status: Value(op.status.code),
          language: Value(language),
        ),
        expectedVersion: op.expectedVersion,
      ),
    ]);
  }
}
