import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_state.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart'
    show GeneratorProposalIds;
import 'package:fb_mobile/features/buddy/application/turn/agent_card_writer.dart';
import 'package:fb_mobile/features/buddy/data/records/record_facts_loader.dart';
import 'package:fb_mobile/features/buddy/data/records/record_intents.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_cards.g.dart';

/// The budget a record card's holder row carries (A67 D2): it marks the
/// row as a card holder for history and restore; no food session reads it.
const recordHolderBudget = '{"record":1}';

/// The draft a record card's proposal row keeps (its plan is re-made from
/// current rows when it is reopened).
const recordDraftJson = '{"revision":0}';

/// The proposal codec version of record rows.
const recordCodecVersion = 1;

/// What confirming a record card gave.
sealed class RecordConfirmOutcome {
  const new _();
}

/// Written: [card] is logged; its undo entry reverts it.
final class RecordConfirmed extends RecordConfirmOutcome {
  /// The outcome.
  const new(this.card) : super._();

  /// The logged card.
  final RecordCard card;
}

/// Nothing was written: the rows behind the card changed; [card] is
/// re-planned from current rows (or `null` when it can't be any more).
final class RecordChanged extends RecordConfirmOutcome {
  /// The outcome.
  const new(this.card) : super._();

  /// The re-planned card.
  final RecordCard? card;
}

/// Nothing was written.
final class RecordNotSaved extends RecordConfirmOutcome {
  /// The outcome.
  const new() : super._();
}

/// Writes record cards (A67 D2, D3): a `proposal` event becomes a pending
/// card with its own holder row (never a domain row); confirm writes the
/// plan's ops and the resolve in one change set with
/// `Origin.proposal(card)` and one undo entry; discard is undoable;
/// supersede is the system's. Nothing here logs.
final class RecordCards {
  /// The service over its ports.
  const new({
    required this._apply,
    required this._undo,
    required this._ids,
    required this._loader,
  });

  final Future<ApplyResult> Function(ChangeSet) _apply;
  final UndoStack _undo;
  final IdGenerator _ids;
  final RecordFactsLoader _loader;

  static bool _never() => false;

  /// The plan of [intent] at [time] (with [choice] / [path] picked).
  Future<RecordPlan?> plan(
    RecordIntent intent,
    EntryTime time, {
    String? choice,
    BatchPath? path,
    Set<String>? cardEntryIds,
  }) async {
    final ids = GeneratorProposalIds(_ids);
    final facts = await _loader.load(
      intent,
      time,
      ids: ids,
      cardEntryIds: cardEntryIds,
    );
    if (facts == null) return null;
    return RecordPlanner.plan(
      intent.request,
      facts,
      ids,
      choice: choice,
      path: path,
    );
  }

  /// Plans [raw] as card [cardId] for user message [userId] and writes it
  /// pending with [checkpoint]; `null` when it can't be a card (another
  /// kind, an issue) or wasn't written.
  Future<RecordCard?> create({
    required Map<String, Object?> raw,
    required int revision,
    required String cardId,
    required String userId,
    required EntryTime referenceTime,
    required String checkpoint,
    Set<String>? cardEntryIds,
    bool Function() cancelled = _never,
  }) async {
    final intent = decodeRecordIntent(raw);
    if (intent == null) return null;
    final plan = await this.plan(
      intent,
      referenceTime,
      cardEntryIds: cardEntryIds,
    );
    final view = plan?.view;
    if (plan == null || view == null) return null;
    final holderId = _ids.next();
    final answer = jsonEncode(
      AgentCardWriter.answerOf(raw, revision: revision),
    );
    if (cancelled()) return null;
    final result = await _apply(
      ChangeSet([
        _holder(holderId, userId, view, answer),
        SetChatMessageBudget(holderId, recordCodecVersion, recordHolderBudget),
        CreateProposal(
          cardId,
          ProposalRowDraft(
            kind: intent.request.kind.code,
            originMessageId: holderId,
            budgetMessageId: holderId,
            codecVersion: recordCodecVersion,
            interpretationJson: jsonEncode(raw),
            draftJson: recordDraftJson,
          ),
        ),
        SaveTurnCheckpoint(userId, checkpoint),
      ], origin: Origin.system),
    );
    if (result is! Applied) return null;
    return RecordCard(
      id: cardId,
      intent: intent,
      raw: raw,
      plan: plan,
      holderId: holderId,
      referenceTime: referenceTime,
      revision: revision,
    );
  }

  /// Updates open [card] with [raw] (a `replaces`, A67 D3) into a new
  /// holder answering [userId]; `null` when it can't be planned or the
  /// row moved on (resolved meanwhile).
  Future<RecordCard?> update({
    required RecordCard card,
    required Map<String, Object?> raw,
    required int revision,
    required String userId,
    required String checkpoint,
    Set<String>? cardEntryIds,
    bool Function() cancelled = _never,
  }) async {
    final intent = decodeRecordIntent(raw);
    if (intent == null || intent.request.kind != card.kind) return null;
    final plan = await this.plan(
      intent,
      card.referenceTime,
      cardEntryIds: cardEntryIds,
    );
    final view = plan?.view;
    if (plan == null || view == null) return null;
    final holderId = _ids.next();
    final answer = jsonEncode(
      AgentCardWriter.answerOf(raw, revision: revision),
    );
    if (cancelled()) return null;
    final result = await _apply(
      ChangeSet([
        _holder(holderId, userId, view, answer),
        SetChatMessageBudget(holderId, recordCodecVersion, recordHolderBudget),
        SaveProposalDraft(
          card.id,
          expectedBudgetMessageId: card.holderId,
          budgetMessageId: holderId,
          codecVersion: recordCodecVersion,
          interpretationJson: jsonEncode(raw),
          draftJson: recordDraftJson,
          requirePending: true,
        ),
        ReleaseChatMessageAnswer(card.holderId),
        SaveTurnCheckpoint(userId, checkpoint),
      ], origin: Origin.system),
    );
    if (result is! Applied) return null;
    return card.copyWith(
      intent: intent,
      raw: raw,
      plan: plan,
      holderId: holderId,
      revision: revision,
    );
  }

  static CreateChatMessage _holder(
    String id,
    String userId,
    RecordView view,
    String answer,
  ) => CreateChatMessage(
    id,
    ChatMessageDraft(
      role: ChatMessageRole.assistant,
      text: ChatText.sanitize(recordLabel(view)),
      status: ChatMessageStatus.done,
      language: ChatLanguage.english,
      replyToMessageId: userId,
    ),
    answerJson: isLocalJsonObject(answer) ? answer : null,
  );

  ResolveProposal _resolve(
    RecordCard card,
    ProposalStatus to,
    ProposalOutcome outcome,
  ) => ResolveProposal(
    card.id,
    expectedBudgetMessageId: card.holderId,
    to: to,
    outcome: outcome,
    codecVersion: recordCodecVersion,
    interpretationJson: jsonEncode(card.raw),
    draftJson: recordDraftJson,
  );

  /// The ops a confirm of [card] writes: its plan's ops and the resolve
  /// (`adjusted` when the user changed the batch path), its holder's local
  /// answer released. Empty when it can't be confirmed with one tap.
  List<ChangeOp> confirmOps(RecordCard card) {
    if (!card.plan.canConfirm) return const [];
    return [
      ...card.plan.ops,
      _resolve(
        card,
        ProposalStatus.confirmed,
        card.path == null
            ? ProposalOutcome.unchanged
            : ProposalOutcome.adjusted,
      ),
      ReleaseChatMessageAnswer(card.holderId),
    ];
  }

  /// Confirms [cards] in **one** change set with one undo entry (Apply
  /// all over record cards, AI-162): the confirmed cards, or `null` when
  /// nothing was written.
  Future<List<RecordCard>?> confirmAll(List<RecordCard> cards) async {
    final ops = [for (final c in cards) ...confirmOps(c)];
    if (cards.isEmpty || ops.isEmpty || ops.length > ChangeSet.maxOps) {
      return null;
    }
    final result = await _apply(
      ChangeSet(ops, origin: Origin.proposal(cards.first.id)),
    );
    if (result is! Applied) return null;
    final entry = _undo.record(result, UndoLabel('proposalLogged'));
    return [
      for (final c in cards)
        c.copyWith(
          resolution: CardResolution.logged,
          undoEntryId: entry.id,
          appliedAt: entry.appliedAt,
        ),
    ];
  }

  /// The resolve a confirm made somewhere else writes with its own ops
  /// (the personal-food form, A67 D8): [adjusted] when the user changed
  /// what Buddy prepared.
  List<ChangeOp> resolveOps(RecordCard card, {required bool adjusted}) => [
    _resolve(
      card,
      ProposalStatus.confirmed,
      adjusted ? ProposalOutcome.adjusted : ProposalOutcome.unchanged,
    ),
    ReleaseChatMessageAnswer(card.holderId),
  ];

  /// Confirms [card] (one change set, one undo entry). A row that changed
  /// meanwhile re-plans the card instead; after an Undo (its new IDs are
  /// tombstones) it is re-planned with fresh IDs and confirmed once more.
  Future<RecordConfirmOutcome> confirm(
    RecordCard card, {
    Set<String>? cardEntryIds,
    bool retried = false,
  }) async {
    final ops = confirmOps(card);
    if (ops.isEmpty || ops.length > ChangeSet.maxOps) {
      return const RecordNotSaved();
    }
    final result = await _apply(
      ChangeSet(ops, origin: Origin.proposal(card.id)),
    );
    switch (result) {
      case Applied():
        final entry = _undo.record(result, UndoLabel('proposalLogged'));
        return RecordConfirmed(
          card.copyWith(
            resolution: CardResolution.logged,
            undoEntryId: entry.id,
            appliedAt: entry.appliedAt,
            changedMeanwhile: false,
            couldNotSave: false,
          ),
        );
      case Rejected(:final failure):
        final fresh = await replan(card, cardEntryIds: cardEntryIds);
        if (failure case ConstraintViolation(code: 'duplicateId')
            when !retried && fresh != null && fresh.plan.canConfirm) {
          return await confirm(
            fresh,
            cardEntryIds: cardEntryIds,
            retried: true,
          );
        }
        if (failure is VersionConflict ||
            failure is RowNotFound ||
            failure is ConstraintViolation ||
            failure is InvalidOp) {
          // Open again with the current rows: the user checks and
          // confirms (or discards) the new plan (A67 review 1).
          return RecordChanged(
            fresh?.copyWith(
              resolution: CardResolution.open,
              changedMeanwhile: true,
            ),
          );
        }
        return const RecordNotSaved();
    }
  }

  /// [card] re-planned from current rows with fresh IDs (its pick and path
  /// kept), or `null` when it can't be planned.
  Future<RecordCard?> replan(
    RecordCard card, {
    Set<String>? cardEntryIds,
  }) async {
    final plan = await this.plan(
      card.intent,
      card.referenceTime,
      choice: card.choice,
      path: card.path,
      cardEntryIds: cardEntryIds,
    );
    if (plan == null || plan.view == null) return null;
    return card.copyWith(plan: plan);
  }

  /// Discards [card] (undoable; [system] for a retry's supersede, no
  /// undo). The discarded card, or `null` when nothing was written.
  Future<RecordCard?> discard(RecordCard card, {bool system = false}) async {
    final result = await _apply(
      ChangeSet([
        _resolve(card, ProposalStatus.discarded, ProposalOutcome.discarded),
        ReleaseChatMessageAnswer(card.holderId),
      ], origin: Origin.system),
    );
    if (result is! Applied) return null;
    if (system) return card.copyWith(resolution: CardResolution.superseded);
    final entry = _undo.record(result, UndoLabel('proposalDiscarded'));
    return card.copyWith(
      resolution: CardResolution.discarded,
      undoEntryId: entry.id,
      appliedAt: entry.appliedAt,
    );
  }

  /// Undoes confirm or discard [undoEntryId] (the whole change set, or
  /// nothing when a row changed since).
  Future<UndoOutcome> undo(String undoEntryId) => _undo.undo(undoEntryId);

  /// Reopens stored pending card [record] held by its budget row (A67 D2): its
  /// plan made from current rows; `null` when it can't be any more.
  Future<RecordCard?> restore(
    ProposalRecord record,
    EntryTime referenceTime, {
    int revision = 1,
    bool requireView = true,
  }) async {
    final json = record.interpretationJson;
    final holder = record.budgetMessageId;
    if (json == null || holder == null) return null;
    final Object? raw;
    try {
      raw = jsonDecode(json);
    } on FormatException {
      return null;
    }
    if (raw is! Map<String, Object?>) return null;
    final intent = decodeRecordIntent(raw);
    if (intent == null) return null;
    final plan =
        await this.plan(intent, referenceTime) ??
        RecordPlan.failed(intent.request.kind, RecordIssue.notFound);
    if (requireView && plan.view == null) return null;
    return RecordCard(
      id: record.id,
      intent: intent,
      raw: raw,
      plan: plan,
      holderId: holder,
      referenceTime: referenceTime,
      revision: revision,
    );
  }

  @override
  String toString() => 'RecordCards';
}

/// The app's record cards.
@Riverpod(keepAlive: true)
RecordCards recordCards(Ref ref) => RecordCards(
  apply: ref.watch(changeSetApplierProvider).apply,
  undo: ref.watch(undoStackProvider),
  ids: ref.watch(idGeneratorProvider),
  loader: ref.watch(recordFactsLoaderProvider),
);
