import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/chat_tables.dart';
import 'package:fb_mobile/features/buddy/data/chat_message_mappers.dart';

/// Plans `chat_messages` rows inside the applier's transaction (A22 D5,
/// A23 D5/D6).
///
/// Re-checks every wire rule at the boundary and rejects with
/// `InvalidOp(code)`, never truncating: callers sanitize first
/// (`ChatText.sanitize`). A rejection names a code, never the text. A budget
/// write needs a live assistant row (`proposalMessageMissing`) and never
/// lowers the stored codec revision (`proposalStale`).
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
    SetChatMessageBudget() => await _setBudget(op, tx),
    ReleaseChatMessageAnswer() => await _release(op, tx),
  };

  Future<OpPlan> _release(ReleaseChatMessageAnswer op, TxReader tx) async {
    final row = await tx.liveRow(db.chatMessages, op.id);
    if (row == null || row.answerJson == null) return OpPlan(const []);
    final pending =
        await (tx.db.selectOnly(db.proposals)
              ..addColumns([db.proposals.id])
              ..where(
                db.proposals.budgetMessageId.equals(op.id) &
                    db.proposals.status.equals(ProposalStatus.pending.code) &
                    db.proposals.deletedAt.isNull(),
              )
              ..limit(1))
            .get();
    if (pending.isNotEmpty) return OpPlan(const []);
    return OpPlan([
      UpdateRow(
        db.chatMessages,
        op.id,
        const ChatMessagesCompanion(answerJson: Value(null)),
        expectedVersion: row.version,
      ),
    ]);
  }

  OpPlan _create(CreateChatMessage op) {
    if (op.validate() case final invalid?) {
      throw ChangeRejected(InvalidOp(invalid.code));
    }
    return OpPlan([
      InsertRow(
        db.chatMessages,
        chatMessageColumns(op.id, op.draft, answerJson: op.answerJson),
      ),
    ]);
  }

  Future<OpPlan> _setBudget(SetChatMessageBudget op, TxReader tx) async {
    if (op.validate() case final invalid?) {
      throw ChangeRejected(InvalidOp(invalid.code));
    }
    final row = await tx.liveRow(db.chatMessages, op.id);
    if (row == null || row.role != ChatMessageRole.assistant.code) {
      throw const ChangeRejected(InvalidOp('proposalMessageMissing'));
    }
    final stored = proposalRevisionOf(row.budgetJson);
    final incoming = proposalRevisionOf(op.budgetJson);
    if (stored != null && incoming != null && incoming < stored) {
      throw const ChangeRejected(InvalidOp('proposalStale'));
    }
    final clear = op.clearAnswer && row.answerJson != null;
    if (row.codecVersion == op.codecVersion &&
        row.budgetJson == op.budgetJson &&
        !clear) {
      return OpPlan(const []);
    }
    return OpPlan([
      UpdateRow(
        db.chatMessages,
        op.id,
        ChatMessagesCompanion(
          codecVersion: Value(op.codecVersion),
          budgetJson: Value(op.budgetJson),
          answerJson: clear ? const Value(null) : const Value.absent(),
        ),
        expectedVersion: row.version,
      ),
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
