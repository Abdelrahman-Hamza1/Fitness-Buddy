import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/chat_tables.dart';
import 'package:fb_mobile/features/buddy/data/proposal_mappers.dart';

/// Plans `proposals` rows inside the applier's transaction (A23 D5, D6).
///
/// Re-checks every rule at the boundary and rejects with `InvalidOp(code)`,
/// never truncating; a rejection rolls back the whole change set (the diary
/// ops of a confirm included). Codes name the rule, never the content:
/// `proposalResolved` (not pending), `proposalRebound` (bound to another
/// message), `proposalMessageMissing` (no live assistant budget row),
/// `proposalStale` (an older codec revision than the stored one),
/// `proposalResolution` (not a confirm/discard pair) and the
/// [InvalidProposal] codes.
final class ProposalOpHandler extends ChangeOpHandler<ProposalOp> {
  /// Bound to the applier's database.
  const new(this.db);

  /// Profile database.
  final AppDatabase db;

  @override
  String get family => ProposalOp.familyName;

  @override
  Future<OpPlan> plan(ProposalOp op, TxReader tx, ApplyContext context) async =>
      switch (op) {
        CreateProposal() => await _create(op, tx),
        SaveProposalDraft() => await _save(op, tx),
        ResolveProposal() => await _resolve(op, tx, context),
      };

  Future<OpPlan> _create(CreateProposal op, TxReader tx) async {
    if (op.validate() case final invalid?) {
      throw ChangeRejected(InvalidOp(invalid.code));
    }
    if (op.draft.budgetMessageId case final message?) {
      await _requireAssistant(tx, message);
    }
    return OpPlan([InsertRow(db.proposals, proposalColumns(op.id, op.draft))]);
  }

  Future<OpPlan> _save(SaveProposalDraft op, TxReader tx) async {
    final row = await _bound(tx, op.id, op.expectedBudgetMessageId);
    if (op.requirePending && row.status != ProposalStatus.pending.code) {
      throw const ChangeRejected(InvalidOp('proposalResolved'));
    }
    _checkContent(
      row,
      budgetMessageId: op.budgetMessageId,
      codecVersion: op.codecVersion,
      interpretationJson: op.interpretationJson,
      draftJson: op.draftJson,
    );
    if (op.budgetMessageId case final message?
        when message != row.budgetMessageId) {
      await _requireAssistant(tx, message);
    }
    if (row.budgetMessageId == op.budgetMessageId &&
        row.codecVersion == op.codecVersion &&
        row.interpretationJson == op.interpretationJson &&
        row.draftJson == op.draftJson) {
      return OpPlan(const []);
    }
    return OpPlan([
      UpdateRow(
        db.proposals,
        op.id,
        ProposalsCompanion(
          budgetMessageId: Value(op.budgetMessageId),
          codecVersion: Value(op.codecVersion),
          interpretationJson: Value(op.interpretationJson),
          draftJson: Value(op.draftJson),
        ),
        expectedVersion: row.version,
      ),
    ]);
  }

  Future<OpPlan> _resolve(
    ResolveProposal op,
    TxReader tx,
    ApplyContext context,
  ) async {
    if (!op.isResolution) {
      throw const ChangeRejected(InvalidOp('proposalResolution'));
    }
    final row = await _bound(tx, op.id, op.expectedBudgetMessageId);
    if (row.status != ProposalStatus.pending.code) {
      throw const ChangeRejected(InvalidOp('proposalResolved'));
    }
    _checkContent(
      row,
      // Discarding closes even a row that broke the foodLog pairing (a
      // synced row with no refs, A23 D13).
      pairing: op.to != ProposalStatus.discarded,
      budgetMessageId: row.budgetMessageId,
      codecVersion: op.codecVersion,
      interpretationJson: op.interpretationJson,
      draftJson: op.draftJson,
    );
    return OpPlan([
      UpdateRow(
        db.proposals,
        op.id,
        ProposalsCompanion(
          status: Value(op.to.code),
          outcome: Value(op.outcome.code),
          resolvedAt: Value(context.nowUtc.millisecondsSinceEpoch),
          codecVersion: Value(op.codecVersion),
          interpretationJson: Value(op.interpretationJson),
          draftJson: Value(op.draftJson),
        ),
        expectedVersion: row.version,
      ),
    ]);
  }

  /// The live row [id], bound to [expected].
  Future<ProposalRow> _bound(TxReader tx, String id, String? expected) async {
    final row = await tx.liveRow(db.proposals, id);
    if (row == null) {
      throw ChangeRejected(RowNotFound(entity: proposalEntity, id: id));
    }
    if (row.budgetMessageId != expected) {
      throw const ChangeRejected(InvalidOp('proposalRebound'));
    }
    return row;
  }

  /// The content rules of every write and the revision guard (A23 D6).
  void _checkContent(
    ProposalRow row, {
    required String? budgetMessageId,
    required int codecVersion,
    required String? interpretationJson,
    required String draftJson,
    bool pairing = true,
  }) {
    if (budgetMessageId != null && !isUuid(budgetMessageId)) {
      throw ChangeRejected(InvalidOp(InvalidProposal.ref.code));
    }
    if (validateProposalContent(
          kind: pairing ? row.kind : '',
          originMessageId: row.originMessageId,
          budgetMessageId: budgetMessageId,
          codecVersion: codecVersion,
          interpretationJson: interpretationJson,
          draftJson: draftJson,
        )
        case final invalid?) {
      throw ChangeRejected(InvalidOp(invalid.code));
    }
    final stored = proposalRevisionOf(row.draftJson);
    final incoming = proposalRevisionOf(draftJson);
    if (stored != null && incoming != null && incoming < stored) {
      throw const ChangeRejected(InvalidOp('proposalStale'));
    }
  }

  /// A budget binding needs a live assistant row (in this change set too).
  Future<void> _requireAssistant(TxReader tx, String messageId) async {
    final message = await tx.liveRow(db.chatMessages, messageId);
    if (message == null || message.role != ChatMessageRole.assistant.code) {
      throw const ChangeRejected(InvalidOp('proposalMessageMissing'));
    }
  }
}
