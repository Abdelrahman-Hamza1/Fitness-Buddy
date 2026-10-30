import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';

/// A card resolved in a session write: [cardId] becomes [to] with
/// [outcome].
final class ResolvedCard {
  /// The resolution.
  const new(this.cardId, this.to, this.outcome);

  /// The card.
  final String cardId;

  /// `confirmed` or `discarded`.
  final ProposalStatus to;

  /// How it ended.
  final ProposalOutcome outcome;

  @override
  String toString() => 'ResolvedCard($cardId, ${to.code})';
}

/// Turns message sessions into proposal and budget ops (A23 D7, D8): the
/// **only** producer of assistant-message budget ops. Pure: no I/O, no
/// clock, no IDs.
///
/// Every write covers **all member cards** of each message session it
/// touches plus that message's budget, at the session's one revision, so a
/// restore by `budgetMessageId` always finds one consistent session. Rows
/// store the full local draft (the codec's raw encoders); the sync mapper
/// decides whether it fits the wire (A23 D15).
abstract final class ProposalSessionWriter {
  /// The stored `(interpretationJson, draftJson)` of card [cardId].
  static (String, String) fields(ProposalSession session, String cardId) {
    final card = ProposalDraftCodec.encodeCard(session, cardId);
    final interpretation = jsonEncode(card.remove('interpretation'));
    return (interpretation, jsonEncode(card));
  }

  /// [session]'s budget, with [departed] cards listed as moved away.
  static String budget(
    ProposalSession session, {
    Set<String> departed = const {},
  }) {
    final ids = {for (final c in session.cards) c.id};
    return jsonEncode(
      ProposalDraftCodec.encodeMessageBudget(
        session,
        // Restored sessions keep their departed cards in the engine.
        movedCardIds: departed.where(ids.contains),
      ),
    );
  }

  /// Whether [session]'s budget fits the 32768-unit wire bound (a reply's
  /// budget is far below it, rec R9).
  static bool budgetFits(ProposalSession session) =>
      ProposalDraftCodec.fitsSyncString(budget(session));

  /// A reply's ops (after the `CreateChatMessage` of [messageId]): its
  /// budget and one pending row per card. None without cards, or when the
  /// budget doesn't fit (the reply is then saved as text only).
  static List<ChangeOp> reply(ProposalSession session, String messageId) {
    if (session.cards.isEmpty || !budgetFits(session)) return const [];
    return [
      SetChatMessageBudget(
        messageId,
        ProposalDraftCodec.version,
        budget(session),
      ),
      for (final card in session.cards) _create(session, card),
    ];
  }

  /// The whole session of [session]'s message: every member saved (or
  /// [resolve]d), then the budget. [moving] cards leave the message in this
  /// write (a follow-up or rebuild). The budget write clears the message's
  /// local answer once no member is pending (rec R8).
  static List<ChangeOp> write(
    ProposalSession session,
    SessionMembership membership, {
    ResolvedCard? resolve,
    Set<String> moving = const {},
  }) {
    final message = SessionMembership.messageOf(session);
    if (message == null) return const [];
    final departed = {...membership.departedFrom(message), ...moving};
    final members = [
      for (final c in session.cards)
        if (!departed.contains(c.id)) c,
    ];
    return [
      for (final card in members)
        if (card.id == resolve?.cardId)
          _resolve(session, card, resolve!)
        else
          _save(session, card, from: message),
      SetChatMessageBudget(
        message,
        ProposalDraftCodec.version,
        budget(session, departed: departed),
        clearAnswer: !members.any((c) => c.lifecycle == .active),
      ),
    ];
  }

  /// A follow-up or rebuild that moved [card] from [source]'s message into
  /// [target] (the new message's one-card session): the card rebound with
  /// its new content, the new budget, then the source's remaining members
  /// and its budget with the card departed (A23 D7, PA2).
  static List<ChangeOp> move(
    ProposalCard card,
    ProposalSession target,
    ProposalSession source,
    SessionMembership membership,
  ) {
    final from = SessionMembership.messageOf(source);
    final to = SessionMembership.messageOf(target);
    final moved = target.cards.where((c) => c.id == card.id).firstOrNull;
    if (from == null || to == null || moved == null) return const [];
    return [
      _save(target, moved, from: from, requirePending: true),
      SetChatMessageBudget(to, ProposalDraftCodec.version, budget(target)),
      ...write(source, membership, moving: {card.id}),
    ];
  }

  static CreateProposal _create(ProposalSession session, ProposalCard card) {
    final (interpretation, draft) = fields(session, card.id);
    return CreateProposal(
      card.id,
      ProposalRowDraft(
        kind: foodLogKind,
        originMessageId: card.originMessageId,
        budgetMessageId: card.budgetMessageId,
        codecVersion: ProposalDraftCodec.version,
        interpretationJson: interpretation,
        draftJson: draft,
      ),
    );
  }

  static SaveProposalDraft _save(
    ProposalSession session,
    ProposalCard card, {
    required String from,
    bool requirePending = false,
  }) {
    final (interpretation, draft) = fields(session, card.id);
    return SaveProposalDraft(
      card.id,
      expectedBudgetMessageId: from,
      budgetMessageId: card.budgetMessageId,
      codecVersion: ProposalDraftCodec.version,
      interpretationJson: interpretation,
      draftJson: draft,
      requirePending: requirePending,
    );
  }

  static ResolveProposal _resolve(
    ProposalSession session,
    ProposalCard card,
    ResolvedCard resolve,
  ) {
    final (interpretation, draft) = fields(session, card.id);
    return ResolveProposal(
      card.id,
      expectedBudgetMessageId: card.budgetMessageId,
      to: resolve.to,
      outcome: resolve.outcome,
      codecVersion: ProposalDraftCodec.version,
      interpretationJson: interpretation,
      draftJson: draft,
    );
  }
}
