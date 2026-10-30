import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';

import 'package:fb_mobile/features/buddy/application/buddy_issues.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/proposal_persistence_contributor.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_reader.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proposal_resolution.g.dart';

/// Where a card came from: the answer it was built from, the assistant row
/// that owns its budget and the send time. Needed to rebuild it with current
/// facts after a rejected confirm. Holds user content: never logged.
final class CardOrigin {
  /// The origin.
  const new({
    required this.interpretation,
    required this.messageId,
    required this.referenceTime,
  });

  /// The answer JSON.
  final Map<String, Object?> interpretation;

  /// The assistant row (the card's `budgetMessageId`).
  final String messageId;

  /// The engine's reference time.
  final EntryTime referenceTime;

  @override
  String toString() => 'CardOrigin($messageId)';
}

/// What confirming a card gave.
sealed class ConfirmOutcome {
  const new _();
}

/// The card's ops committed as one change set: [session] has it confirmed,
/// with refreshed confirmed totals; [undoEntryId] undoes it (one undo per
/// confirm, D25).
final class CardLogged extends ConfirmOutcome {
  /// The outcome.
  const new({
    required this.session,
    required this.undoEntryId,
    required this.appliedAt,
  }) : super._();

  /// When the change set was applied (UTC): the undo window starts here.
  final DateTime appliedAt;

  /// The recomputed session.
  final ProposalSession session;

  /// The undo stack entry.
  final String undoEntryId;

  @override
  String toString() => 'CardLogged($undoEntryId)';
}

/// Nothing was logged: a food or slot behind the card changed, so it was
/// rebuilt with current facts ([session] holds the new card, same ID), in
/// one change set into its own assistant row [messageId], moved out of
/// message [from] (A23 D11). Both `null` when nothing was written (no
/// contributor).
final class CardRebuilt extends ConfirmOutcome {
  /// The outcome.
  const new(this.session, {this.messageId, this.from, this.interpretation})
    : super._();

  /// The rebuilt card's session.
  final ProposalSession session;

  /// The answer the card was rebuilt from: only its own meals, the card's
  /// origin from now on.
  final Map<String, Object?>? interpretation;

  /// The rebuild's assistant row (M′), now the card's budget message.
  final String? messageId;

  /// The message the card left.
  final String? from;

  @override
  String toString() => 'CardRebuilt';
}

/// Nothing was written and nothing rebuilt ("Couldn't log this card.").
final class CardNotLogged extends ConfirmOutcome {
  /// The outcome.
  const new() : super._();

  @override
  String toString() => 'CardNotLogged';
}

/// What discarding a card gave: the session with it discarded and, when the
/// discard was written, its undo entry (A23 D10).
final class CardDiscarded {
  /// The outcome.
  const new(this.session, {this.undoEntryId, this.appliedAt});

  /// The session with the card discarded.
  final ProposalSession session;

  /// The undo entry of the discard's change set, or `null` when nothing was
  /// written (no contributor).
  final String? undoEntryId;

  /// When the change set was applied (UTC): the undo window starts here.
  final DateTime? appliedAt;

  @override
  String toString() => 'CardDiscarded($undoEntryId)';
}

/// What discarding a card gave, or `null` when its change set was rejected
/// (nothing changed).
typedef DiscardOutcome = CardDiscarded?;

/// Confirm and discard of one proposal card (A22 D12, D25, AI-035–037;
/// A23 D8–D10).
///
/// Confirm composes this card's draft ops plus the contributors'
/// `onConfirm` ops (the version-checked resolve, the outcome, every sibling
/// and the message budget, computed from the resolved session **before**
/// the apply) into one `ChangeSet` with `Origin.proposal(card.id)` and one
/// apply. Nothing from a pending card is ever written before that. Confirm
/// and discard each record one undo entry; undoing reverts the whole change
/// set or nothing.
final class ProposalResolution {
  /// Resolution over its ports.
  const new({
    required this._apply,
    required this._undo,
    required this._loader,
    required this._ids,
    required this._contributors,
    BuddyIssueSink? report,
  }) : _report = report ?? _ignore;

  static void _ignore(BuddyIssue _) {}

  final Future<ApplyResult> Function(ChangeSet) _apply;
  final UndoStack _undo;
  final ProposalInputLoader _loader;
  final IdGenerator _ids;
  final List<ProposalPersistenceContributor> _contributors;
  final BuddyIssueSink _report;

  /// Confirms [cardId] of [session]. A card that can't be confirmed writes
  /// nothing ([CardNotLogged]).
  Future<ConfirmOutcome> confirm(
    ProposalSession session,
    String cardId,
    CardOrigin origin, {
    SessionMembership membership = const SessionMembership(),
    bool reidentified = false,
  }) async {
    final card = session.cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null || !card.canConfirm) return const CardNotLogged();
    // The stored rows are the post-resolution state (A23 D8).
    final resolved = ProposalEngine.recompute(
      session,
      ProposalSetLifecycle(card.id, ProposalLifecycle.confirmed),
    ).value?.session;
    if (resolved == null) return const CardNotLogged();
    final ops = [
      ...card.draftOps,
      for (final c in _contributors) ...c.onConfirm(card, resolved, membership),
    ];
    if (ops.length > ChangeSet.maxOps) return const CardNotLogged();
    final result = await _apply(
      ChangeSet(ops, origin: Origin.proposal(card.id)),
    );
    switch (result) {
      case Applied():
        final entry = _undo.record(result, UndoLabel('proposalLogged'));
        // Written and undoable from here: a failing refresh must never make
        // a logged card look unlogged (the user would log it twice). The
        // previews stay as they were until the next refresh (A22a review
        // round 2); only the issue type is reported.
        ProposalSession next;
        try {
          next = await refresh(
            session,
            origin.referenceTime,
            confirmedCardId: card.id,
          );
          // Any throw here: the write already happened.
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {
          _report(const BuddyRefreshFailed());
          next = resolved;
        }
        return CardLogged(
          session: next,
          undoEntryId: entry.id,
          appliedAt: entry.appliedAt,
        );
      case Rejected(failure: ConstraintViolation(code: 'duplicateId'))
          when !reidentified && !await _loader.anyLiveDiaryRow(_diaryIds(card)):
        // Its entry IDs are only tombstones (an undone confirm, even one
        // interrupted before anything else was saved, A23 D10): the card
        // gets fresh ones, written by this confirm's one change set.
        final fresh = ProposalEngine.recompute(
          session,
          ProposalReidentify(card.id, GeneratorProposalIds(_ids)),
        ).value?.session;
        if (fresh == null) return const CardNotLogged();
        return await confirm(
          fresh,
          cardId,
          origin,
          membership: membership,
          reidentified: true,
        );
      case Rejected(:final failure):
        if (!isFactChange(failure)) return const CardNotLogged();
        return await rebuild(
              session,
              card.id,
              origin,
              membership: membership,
            ) ??
            const CardNotLogged();
    }
  }

  /// Rebuilds open card [cardId] of [session] from [origin]'s answer with
  /// the current food facts (a rejected confirm; "Update card" on a stale
  /// restored card), offline (A23 D11, D13). The card moves to a new
  /// assistant row M′ (no `replyToMessageId`, the fixed transcript text,
  /// the answer kept locally) that owns its budget; the source message's
  /// remaining members and budget are written in the same change set.
  /// `null` when it can't be rebuilt or the change set was rejected.
  Future<CardRebuilt?> rebuild(
    ProposalSession session,
    String cardId,
    CardOrigin origin, {
    SessionMembership membership = const SessionMembership(),
  }) async {
    final card = session.cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null || card.lifecycle != ProposalLifecycle.active) {
      return null;
    }
    final messageId = _ids.next();
    final own = ownAnswer(session, cardId, origin.interpretation);
    final request = await _loader.load(
      interpretation: own,
      messageId: messageId,
      idSource: GeneratorProposalIds(_ids),
      referenceTime: origin.referenceTime,
      days: {card.preview.date},
    );
    final fresh = request.value;
    final rebuilt = fresh == null
        ? null
        : ProposalEngine.rebuild(card, fresh).value?.session;
    final moved = rebuilt?.cards.where((c) => c.id == cardId).firstOrNull;
    if (rebuilt == null || moved == null) return null;
    final ops = [
      for (final c in _contributors)
        ...c.onFollowUp(
          moved,
          rebuilt,
          messageId,
          from: session,
          membership: membership,
        ),
    ];
    if (ops.isEmpty) return CardRebuilt(rebuilt, interpretation: own);
    final answer = jsonEncode(own);
    final result = await _apply(
      ChangeSet([
        CreateChatMessage(
          messageId,
          const ChatMessageDraft(
            role: ChatMessageRole.assistant,
            text: BuddyReplyTexts.cardRebuiltRecord,
            status: ChatMessageStatus.done,
            language: ChatLanguage.english,
          ),
          answerJson: isLocalJsonObject(answer) ? answer : null,
        ),
        ...ops,
      ], origin: Origin.system),
    );
    if (result is! Applied) return null;
    return CardRebuilt(
      rebuilt,
      messageId: messageId,
      from: SessionMembership.messageOf(session),
      interpretation: own,
    );
  }

  static bool _isObject(String json) {
    try {
      return jsonDecode(json) is Map<String, Object?>;
    } on FormatException {
      return false;
    }
  }

  /// The diary row IDs [card]'s ops would insert.
  static Set<String> _diaryIds(ProposalCard card) => {
    for (final op in card.draftOps)
      ...switch (op) {
        LogEntries(:final entries) => entries.map((e) => e.id),
        CreateDishGroup(:final id) => [id],
        _ => const <String>[],
      },
  };

  /// [answer] with only the meals of card [cardId] (by the intent positions
  /// the card was built from): a rebuild of one card from a multi-meal
  /// answer would otherwise merge every meal into it.
  static Map<String, Object?> ownAnswer(
    ProposalSession session,
    String cardId,
    Map<String, Object?> answer,
  ) {
    final intents = answer['intents'];
    if (intents is! List<Object?>) return answer;
    final card = ProposalDraftCodec.encodeCard(session, cardId);
    final indexes = {
      for (final i in card['interpretation']! as List<Object?>)
        if (i case [final int index, ...]) index,
    };
    return {
      ...answer,
      'intents': [
        for (final (index, intent) in intents.indexed)
          if (indexes.contains(index)) intent,
      ],
    };
  }

  /// Discards [cardId]: the contributors' ops (the resolve with its
  /// `discarded` outcome, the siblings and the budget) as one undoable
  /// change set; in memory only when no contributor adds any.
  Future<DiscardOutcome> discard(
    ProposalSession session,
    String cardId, {
    SessionMembership membership = const SessionMembership(),
  }) async {
    final card = session.cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null || card.lifecycle != ProposalLifecycle.active) {
      return null;
    }
    final resolved = ProposalEngine.recompute(
      session,
      ProposalSetLifecycle(card.id, ProposalLifecycle.discarded),
    ).value?.session;
    if (resolved == null) return null;
    final ops = [
      for (final c in _contributors) ...c.onDiscard(card, resolved, membership),
    ];
    if (ops.isEmpty) return CardDiscarded(resolved);
    if (ops.length > ChangeSet.maxOps) return null;
    final result = await _apply(ChangeSet(ops, origin: Origin.system));
    if (result is! Applied) return null;
    final entry = _undo.record(result, UndoLabel('proposalDiscarded'));
    return CardDiscarded(
      resolved,
      undoEntryId: entry.id,
      appliedAt: entry.appliedAt,
    );
  }

  /// Discards stored card [record], whose session can't be reopened (A23
  /// D13): its row alone is resolved as stored, one undoable change set.
  /// The undo entry and when it was applied, or `null` when rejected.
  Future<(String, DateTime)?> discardRecord(ProposalRecord record) async {
    if (!record.isPending) return null;
    final result = await _apply(
      ChangeSet([
        ResolveProposal(
          record.id,
          expectedBudgetMessageId: record.budgetMessageId,
          to: ProposalStatus.discarded,
          outcome: ProposalOutcome.discarded,
          codecVersion: record.codecVersion,
          interpretationJson: record.interpretationJson,
          // A draft that isn't an object (a synced row may hold any JSON
          // root) is closed with the empty draft.
          draftJson: _isObject(record.draftJson) ? record.draftJson : '{}',
        ),
        // Its message's local answer goes once nothing of it waits (even
        // when its budget can't be read; TD-102).
        if (record.budgetMessageId case final message?)
          ReleaseChatMessageAnswer(message),
      ], origin: Origin.system),
    );
    if (result is! Applied) return null;
    final entry = _undo.record(result, UndoLabel('proposalDiscarded'));
    return (entry.id, entry.appliedAt);
  }

  /// Writes [session]'s current state (every member and the budget, A23 D7)
  /// as bookkeeping without an undo entry: done before a confirm or discard
  /// of an adjusted session, so an undo reopens exactly what the user saw.
  /// `false` when the change set was rejected (the resolve then decides).
  Future<bool> persist(
    ProposalSession session,
    SessionMembership membership,
  ) async {
    final ops = [
      for (final c in _contributors) ...c.onSessionChanged(session, membership),
    ];
    if (ops.isEmpty) return true;
    if (ops.length > ChangeSet.maxOps) return false;
    return await _apply(ChangeSet(ops, origin: Origin.system)) is Applied;
  }

  /// Undoes the confirm or discard [undoEntryId] (A23 D10): its whole change
  /// set, or nothing when a row changed since ([UndoOutcome.conflict]).
  Future<UndoOutcome> undo(String undoEntryId) => _undo.undo(undoEntryId);

  /// [session] recomputed with a refreshed context, so every preview counts
  /// confirmed intake once (D12); [confirmedCardId], when given, becomes
  /// confirmed in the same step. Unchanged when the context can't be read.
  Future<ProposalSession> refresh(
    ProposalSession session,
    EntryTime referenceTime, {
    String? confirmedCardId,
  }) async {
    if (session.cards.isEmpty) return session;
    final context = await _loader.refreshContext(
      referenceTime: referenceTime,
      days: {for (final c in session.cards) c.preview.date},
    );
    if (context == null) return session;
    final card = confirmedCardId == null
        ? session.cards.first
        : session.cards.where((c) => c.id == confirmedCardId).firstOrNull;
    if (card == null) return session;
    // Re-stating a card's lifecycle is the engine's context refresh.
    final lifecycle = confirmedCardId == null
        ? card.lifecycle
        : ProposalLifecycle.confirmed;
    return ProposalEngine.recompute(
          session,
          ProposalSetLifecycle(card.id, lifecycle),
          context: context,
        ).value?.session ??
        session;
  }

  /// Whether [failure] means a fact or slot behind the card changed (a
  /// personal food's version, a missing food, a removed or inactive slot):
  /// the only rejections that rebuild the card (PA5). A duplicate ID or any
  /// other rejection never does.
  static bool isFactChange(ChangeFailure failure) => switch (failure) {
    VersionConflict(entity: 'personalFood') ||
    RowNotFound(entity: 'personalFood' || 'mealSlot') => true,
    InvalidOp(code: 'unknownSlot' || 'inactiveSlot' || 'noSlot') => true,
    _ => false,
  };

  @override
  String toString() => 'ProposalResolution';
}

/// The app's proposal resolution.
@Riverpod(keepAlive: true)
ProposalResolution proposalResolution(Ref ref) => ProposalResolution(
  apply: ref.watch(changeSetApplierProvider).apply,
  undo: ref.watch(undoStackProvider),
  loader: ref.watch(proposalInputLoaderProvider),
  ids: ref.watch(idGeneratorProvider),
  contributors: ref.watch(proposalPersistenceContributorsProvider),
  report: ref.watch(buddyIssueSinkProvider),
);
