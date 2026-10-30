import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/proposals/proposal_record.dart';
import 'package:fb_domain/src/proposals/proposal_sync_codes.dart';

/// Proposal-row writes (A23 D5, D6). The handler re-checks every rule in
/// the transaction and rejects with a code, never truncating.
///
/// Creating, saving or rebinding an **unconfirmed** proposal is bookkeeping
/// without an undo entry, like the transcript (A23 D8); only confirm and
/// discard ([ResolveProposal]) are undoable, by their change set.
sealed class ProposalOp implements ChangeOp {
  const new _();

  /// The stable handler family.
  static const familyName = 'proposal';

  @override
  String get family => familyName;

  /// Row ID.
  String get id;
}

/// Saves a new `pending` proposal [id] with [draft]. Its budget message, when
/// set, must be a live assistant row.
final class CreateProposal extends ProposalOp {
  /// New row [id] (a random UUIDv7) with [draft].
  new(this.id, this.draft) : super._() {
    checkUuid(id, 'id');
  }

  @override
  final String id;

  /// The content.
  final ProposalRowDraft draft;

  /// The first rule this op breaks ([id] not a UUIDv7, then
  /// [ProposalRowDraft.validate]), or `null`.
  InvalidProposal? validate() =>
      isUuidV7(id) ? draft.validate() : InvalidProposal.id;

  @override
  bool operator ==(Object other) =>
      other is CreateProposal && other.id == id && other.draft == draft;

  @override
  int get hashCode => Object.hash(CreateProposal, id, draft);

  @override
  String toString() => 'CreateProposal($id, $draft)';
}

/// Saves proposal [id]'s content and binding (A23 D6): its stored budget
/// message must be [expectedBudgetMessageId]; afterwards it is
/// [budgetMessageId] (a follow-up or rebuild passes the new one). Never
/// changes the status; with [requirePending] (the card a follow-up or
/// rebuild moves) a resolved row is rejected with `proposalResolved`.
/// Rejected with `proposalStale` when the codec revision in [draftJson] is
/// lower than the stored one (equal is allowed).
final class SaveProposalDraft extends ProposalOp {
  /// Proposal [id]'s new content.
  new(
    this.id, {
    required this.expectedBudgetMessageId,
    required this.budgetMessageId,
    required this.codecVersion,
    required this.interpretationJson,
    required this.draftJson,
    this.requirePending = false,
  }) : super._() {
    checkUuid(id, 'id');
  }

  @override
  final String id;

  /// The binding the stored row must have.
  final String? expectedBudgetMessageId;

  /// The binding afterwards.
  final String? budgetMessageId;

  /// Whether the stored row must still be pending.
  final bool requirePending;

  /// Engine JSON format version.
  final int codecVersion;

  /// This card's normalized intents.
  final String? interpretationJson;

  /// The compact draft. User content: never logged.
  final String draftJson;

  @override
  bool operator ==(Object other) =>
      other is SaveProposalDraft &&
      other.id == id &&
      other.requirePending == requirePending &&
      other.expectedBudgetMessageId == expectedBudgetMessageId &&
      other.budgetMessageId == budgetMessageId &&
      other.codecVersion == codecVersion &&
      other.interpretationJson == interpretationJson &&
      other.draftJson == draftJson;

  @override
  int get hashCode => Object.hash(
    SaveProposalDraft,
    id,
    requirePending,
    expectedBudgetMessageId,
    budgetMessageId,
    codecVersion,
    interpretationJson,
    draftJson,
  );

  @override
  String toString() => 'SaveProposalDraft($id)';
}

/// Resolves pending proposal [id] (A23 D6): its stored status must be
/// `pending` and its budget message [expectedBudgetMessageId]. Sets [to]
/// (`confirmed` or `discarded`), [outcome] (`unchanged`/`adjusted` for a
/// confirm, `discarded` for a discard), `resolved_at` = the change set's
/// time and the post-resolution content. Rejected with `proposalStale` for a
/// lower codec revision.
final class ResolveProposal extends ProposalOp {
  /// Resolve proposal [id].
  new(
    this.id, {
    required this.expectedBudgetMessageId,
    required this.to,
    required this.outcome,
    required this.codecVersion,
    required this.interpretationJson,
    required this.draftJson,
  }) : super._() {
    checkUuid(id, 'id');
  }

  @override
  final String id;

  /// The binding the stored row must have.
  final String? expectedBudgetMessageId;

  /// The resolved status.
  final ProposalStatus to;

  /// How it ended.
  final ProposalOutcome outcome;

  /// Engine JSON format version.
  final int codecVersion;

  /// This card's normalized intents.
  final String? interpretationJson;

  /// The compact draft after resolution. User content: never logged.
  final String draftJson;

  /// Whether [to] and [outcome] form a resolution.
  bool get isResolution => switch (to) {
    ProposalStatus.confirmed => outcome != ProposalOutcome.discarded,
    ProposalStatus.discarded => outcome == ProposalOutcome.discarded,
    ProposalStatus.pending || ProposalStatus.superseded => false,
  };

  @override
  bool operator ==(Object other) =>
      other is ResolveProposal &&
      other.id == id &&
      other.expectedBudgetMessageId == expectedBudgetMessageId &&
      other.to == to &&
      other.outcome == outcome &&
      other.codecVersion == codecVersion &&
      other.interpretationJson == interpretationJson &&
      other.draftJson == draftJson;

  @override
  int get hashCode => Object.hash(
    ResolveProposal,
    id,
    expectedBudgetMessageId,
    to,
    outcome,
    codecVersion,
    interpretationJson,
    draftJson,
  );

  @override
  String toString() => 'ResolveProposal($id, ${to.code}, ${outcome.code})';
}
