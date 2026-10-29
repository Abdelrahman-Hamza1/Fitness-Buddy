import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/data/buddy_api.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:fb_mobile/features/buddy/data/buddy_api.dart'
    show BuddySendFailure;

part 'buddy_thread_controller.g.dart';

/// Where a turn's request stands.
enum BuddyTurnPhase {
  /// Saved; the interpret call is in flight (skeleton card, AI-030).
  sending,

  /// The call failed ([BuddyTurn.failure]).
  failed,

  /// Buddy answered (the assistant row is saved).
  replied,
}

/// Where a card stands in the thread (D25).
enum CardResolution {
  /// Open: adjustable, Log it offered when it can be confirmed.
  open,

  /// Log it was tapped; the change set is being applied (Log it disabled).
  confirming,

  /// Logged, with one Undo while [BuddyCard.undoEntryId] lasts.
  logged,

  /// Undone: read-only, never offered again.
  undone,

  /// Discarded.
  discarded,
}

/// One card of a turn: the session that currently owns it (a rebuilt card
/// gets its own), its resolution and what changed last.
@immutable
final class BuddyCard {
  /// Card [id] owned by [session].
  const new({
    required this.id,
    required this.session,
    this.resolution = CardResolution.open,
    this.undoEntryId,
    this.diff,
    this.changeToken,
    this.couldNotLog = false,
    this.logged,
    this.undoRefused,
  });

  /// The card's ID.
  final String id;

  /// The session that holds the card now.
  final ProposalSession session;

  /// Where it stands.
  final CardResolution resolution;

  /// The undo entry of its confirm, while [resolution] is logged.
  final String? undoEntryId;

  /// What the last adjustment or rebuild changed (UX-024 highlight).
  final ProposalDiff? diff;

  /// A fresh token per change, so the card highlights again (UX-024).
  final Object? changeToken;

  /// The last confirm failed without a rebuild ("Couldn't log this card.").
  final bool couldNotLog;

  /// What was logged, for the one-line reply (AI-140); kept after the
  /// confirmed card drops its lines.
  final LoggedSummary? logged;

  /// Why the last Undo wrote nothing (too late, changed since); Undo is
  /// then no longer offered.
  final UndoOutcome? undoRefused;

  /// The card itself.
  ProposalCard get card => session.cards.firstWhere((c) => c.id == id);

  /// The question budget the card's questions come from.
  QuestionBudget get budget => session.budget;

  /// A copy with the given fields replaced.
  BuddyCard copyWith({
    ProposalSession? session,
    CardResolution? resolution,
    String? undoEntryId,
    ProposalDiff? diff,
    Object? changeToken,
    bool? couldNotLog,
    LoggedSummary? logged,
    UndoOutcome? undoRefused,
  }) => BuddyCard(
    id: id,
    session: session ?? this.session,
    resolution: resolution ?? this.resolution,
    undoEntryId: undoEntryId ?? this.undoEntryId,
    diff: diff ?? this.diff,
    changeToken: changeToken ?? this.changeToken,
    couldNotLog: couldNotLog ?? this.couldNotLog,
    logged: logged ?? this.logged,
    undoRefused: undoRefused ?? this.undoRefused,
  );

  @override
  String toString() => 'BuddyCard($id, ${resolution.name})';
}

/// What a confirm logged: the card's calories and the day after it.
@immutable
final class LoggedSummary {
  /// [kcal] logged; [preview] is the day with it counted once.
  const new({
    required this.kcal,
    required this.preview,
    this.estimate = false,
    this.loggedAt,
  });

  /// The card's total calories.
  final double kcal;

  /// The day after the confirm (eaten, and left when there's a target).
  final ProposalDayPreview preview;

  /// Some logged items were estimates: the numbers are shown with `~`.
  final bool estimate;

  /// When it was logged (UTC): the one Undo lasts the undo window from
  /// here, not from when the row was first drawn.
  final DateTime? loggedAt;

  @override
  String toString() => 'LoggedSummary';
}

/// One message and what came of it. Holds user content: never logged.
@immutable
final class BuddyTurn {
  /// The turn of [message].
  const new({
    required this.message,
    this.request,
    this.phase = BuddyTurnPhase.sending,
    this.failure,
    this.unavailableCount = 0,
    this.assistantMessageId,
    this.interpretation,
    this.cards = const [],
  });

  /// The saved user message.
  final SavedBuddyMessage message;

  /// The frozen request, replayed by Try again (same Idempotency-Key).
  final PreparedInterpret? request;

  /// Where the request stands.
  final BuddyTurnPhase phase;

  /// Why it failed, when [phase] is failed.
  final BuddySendFailure? failure;

  /// How many 503s this request got; the second stops Try again (D6).
  final int unavailableCount;

  /// The assistant row, once replied.
  final String? assistantMessageId;

  /// The answer, kept to rebuild a card with current facts.
  final Map<String, Object?>? interpretation;

  /// The cards, in order.
  final List<BuddyCard> cards;

  /// The user row's ID.
  String get userMessageId => message.id;

  /// Whether Try again is offered.
  bool get canRetry =>
      phase == BuddyTurnPhase.failed &&
      request != null &&
      (failure?.retryable ?? false) &&
      unavailableCount < 2;

  /// A copy with the given fields replaced.
  BuddyTurn copyWith({
    PreparedInterpret? request,
    BuddyTurnPhase? phase,
    BuddySendFailure? failure,
    int? unavailableCount,
    String? assistantMessageId,
    Map<String, Object?>? interpretation,
    List<BuddyCard>? cards,
  }) => BuddyTurn(
    message: message,
    request: request ?? this.request,
    phase: phase ?? this.phase,
    failure: failure ?? this.failure,
    unavailableCount: unavailableCount ?? this.unavailableCount,
    assistantMessageId: assistantMessageId ?? this.assistantMessageId,
    interpretation: interpretation ?? this.interpretation,
    cards: cards ?? this.cards,
  );

  @override
  String toString() => 'BuddyTurn($userMessageId, ${phase.name})';
}

/// The thread of this app process (D11): turns since launch, oldest first,
/// and text to put back into the composer (after a second 503).
@immutable
final class BuddyThread {
  /// The thread.
  const new({this.turns = const [], this.composerRestore});

  /// The turns.
  final List<BuddyTurn> turns;

  /// Text the composer should take back, once.
  final String? composerRestore;

  /// Whether a send is in flight (Send disabled, D7).
  bool get sending => turns.any((t) => t.phase == BuddyTurnPhase.sending);

  @override
  String toString() => 'BuddyThread(${turns.length} turns)';
}

/// Buddy's thread for this app process (D11): dismissing the sheet keeps it;
/// a restart starts empty (durable restore is A23's).
///
/// Orchestrates the send path, card adjustments, single-flight confirm,
/// discard and the one undo per confirm. Writes only through the use cases
/// (single writer).
@Riverpod(keepAlive: true)
class BuddyThreadController extends _$BuddyThreadController {
  /// A save in flight, before its turn exists (keeps Send single-flight).
  bool _saving = false;

  @override
  BuddyThread build() {
    // A diary change made elsewhere (the sheet closed, a manual log) moves
    // the open cards' "today after this": refresh them (A22a review). This
    // controller lives for the app process, so it hears changes while the
    // sheet is closed. Its own confirms refresh themselves.
    final changes = ref
        .read(domainEventBusProvider)
        .on<ChangeSetApplied>()
        .where(
          (e) =>
              e.origin is! OriginProposal && e.entities.contains('diaryEntry'),
        )
        .listen((_) => unawaited(_refreshOpenCards()));
    ref.onDispose(changes.cancel);
    return const BuddyThread();
  }

  Future<void> _refreshOpenCards() async {
    final open = state.turns.any(
      (t) => t.cards.any((c) => c.resolution == CardResolution.open),
    );
    if (open) await _refreshOthersSafely('');
  }

  SendBuddyMessage get _send => ref.read(sendBuddyMessageProvider);

  ProposalResolution get _resolution => ref.read(proposalResolutionProvider);

  /// Saves [raw], shows the turn at once (skeleton), then interprets it.
  /// Ignored while a send is in flight or for blank text.
  Future<void> send(String raw, BuddyReplyTexts texts) async {
    if (state.sending || _saving) return;
    _saving = true;
    final SavedBuddyMessage? message;
    try {
      message = await _send.save(raw);
    } finally {
      _saving = false;
    }
    if (message == null) return;
    state = BuddyThread(
      turns: [
        ...state.turns,
        BuddyTurn(message: message),
      ],
    );
    try {
      final request = await _send.prepare(message);
      _update(message.id, (t) => t.copyWith(request: request));
      await _dispatch(message.id, texts);
      // A throw must never leave the turn "sending" (Send stays disabled
      // forever): it fails as a server error, retryable when the request
      // was prepared (A22a review). Nothing of it is logged.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      _failed(message.id);
    }
  }

  void _failed(String userMessageId) => _update(
    userMessageId,
    (t) => t.copyWith(
      phase: BuddyTurnPhase.failed,
      failure: BuddySendFailure.server,
    ),
  );

  /// Replays a failed turn's frozen request (same Idempotency-Key), when
  /// [BuddyTurn.canRetry].
  Future<void> retry(String userMessageId, BuddyReplyTexts texts) async {
    final turn = _turn(userMessageId);
    if (turn == null || !turn.canRetry || state.sending) return;
    _update(userMessageId, (t) => t.copyWith(phase: BuddyTurnPhase.sending));
    try {
      await _dispatch(userMessageId, texts);
      // See [send].
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      _failed(userMessageId);
    }
  }

  /// The composer's text to restore, once (then cleared).
  String? takeComposerRestore() {
    final text = state.composerRestore;
    if (text != null) state = BuddyThread(turns: state.turns);
    return text;
  }

  /// Applies a chip/answer [adjustment] to open card [cardId] and recomputes
  /// its session; nothing is written (AI-033, AI-034, AI-036).
  void adjust(String cardId, ProposalAdjustment adjustment) {
    final found = _card(cardId);
    if (found == null || found.$2.resolution != CardResolution.open) return;
    final update = ProposalEngine.recompute(found.$2.session, adjustment).value;
    if (update == null) return;
    _replaceSession(found.$1, found.$2.session, update.session, update.diff);
  }

  /// Logs card [cardId] (one tap, UX-003). Single-flight: a second call
  /// while one applies, or for a card that can't be confirmed, does nothing.
  Future<void> confirm(String cardId) async {
    final found = _card(cardId);
    if (found == null) return;
    final (turn, card) = found;
    if (card.resolution != CardResolution.open || !card.card.canConfirm) {
      return;
    }
    final before = card.card;
    _setCard(
      turn.userMessageId,
      card.copyWith(resolution: CardResolution.confirming, couldNotLog: false),
    );
    final ConfirmOutcome outcome;
    try {
      outcome = await _resolution.confirm(card.session, cardId, _origin(turn));
      // A throw never leaves the card "confirming": it's open again with
      // "Couldn't log this card." (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      _setCard(
        turn.userMessageId,
        _card(cardId)!.$2
            .copyWith(resolution: CardResolution.open, couldNotLog: true),
      );
      return;
    }
    final current = _card(cardId)!.$2;
    switch (outcome) {
      case CardLogged(:final session, :final undoEntryId, :final appliedAt):
        // The day as it is now, from the refreshed session (confirmed
        // intake with this card in it), not the card's pre-confirm preview.
        final after =
            session.cards.where((c) => c.id == cardId).firstOrNull?.preview ??
            before.preview;
        _replaceSession(turn, card.session, session, null);
        _setCard(
          turn.userMessageId,
          _card(cardId)!.$2.copyWith(
            resolution: CardResolution.logged,
            undoEntryId: undoEntryId,
            logged: LoggedSummary(
              kcal: before.totals.kcal,
              preview: after,
              estimate: before.lines.any(
                (l) => l.range != null || l.entry.food.provenance.isEstimate,
              ),
              loggedAt: appliedAt,
            ),
          ),
        );
        await _refreshOthersSafely(cardId);
      case CardRebuilt(:final session):
        _setCard(turn.userMessageId, BuddyCard(id: cardId, session: session));
      case CardNotLogged():
        _setCard(
          turn.userMessageId,
          current.copyWith(resolution: CardResolution.open, couldNotLog: true),
        );
    }
  }

  /// Discards open card [cardId]; nothing is logged (AI-037).
  Future<void> discard(String cardId) async {
    final found = _card(cardId);
    if (found == null || found.$2.resolution != CardResolution.open) return;
    final ProposalSession? session;
    try {
      session = await _resolution.discard(found.$2.session, cardId);
      // A throw leaves the card open (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return;
    }
    if (session == null) return;
    _replaceSession(found.$1, found.$2.session, session, null);
    _setCard(
      found.$1.userMessageId,
      _card(cardId)!.$2.copyWith(resolution: CardResolution.discarded),
    );
  }

  /// Undoes logged card [cardId] once (D25). On success it's read-only
  /// "Undone" and Log it is never offered again.
  Future<UndoOutcome?> undo(String cardId) async {
    final found = _card(cardId);
    final entry = found?.$2.undoEntryId;
    if (found == null ||
        entry == null ||
        found.$2.resolution != CardResolution.logged) {
      return null;
    }
    final UndoOutcome outcome;
    try {
      outcome = await _resolution.undo(entry);
      // A throw leaves the card logged with its Undo (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
    final now = _card(cardId)!.$2;
    _setCard(
      found.$1.userMessageId,
      BuddyCard(
        id: cardId,
        session: now.session,
        diff: now.diff,
        logged: now.logged,
        resolution: outcome == UndoOutcome.undone
            ? CardResolution.undone
            : CardResolution.logged,
        undoRefused: outcome == UndoOutcome.undone ? null : outcome,
      ),
    );
    if (outcome == UndoOutcome.undone) await _refreshOthersSafely(cardId);
    return outcome;
  }

  /// [_refreshOthers], where a failure only leaves sibling previews as they
  /// were: the logged card and its Undo are already shown.
  Future<void> _refreshOthersSafely(String cardId) async {
    try {
      await _refreshOthers(cardId);
      // Any failure here is only a stale preview.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // Previews refresh on the next change.
    }
  }

  Future<void> _dispatch(String userMessageId, BuddyReplyTexts texts) async {
    final turn = _turn(userMessageId)!;
    final reply = await _send.dispatch(turn.message, turn.request!, texts);
    switch (reply) {
      case BuddyReplied(:final assistantMessageId, :final session):
        _update(
          userMessageId,
          (t) => t.copyWith(
            phase: BuddyTurnPhase.replied,
            assistantMessageId: assistantMessageId,
            interpretation: reply.interpretation,
            cards: [
              if (session != null)
                for (final c in session.cards)
                  BuddyCard(id: c.id, session: session),
            ],
          ),
        );
      case BuddyReplyFailed(:final failure):
        final unavailable =
            turn.unavailableCount +
            (failure == BuddySendFailure.unavailable ? 1 : 0);
        _update(
          userMessageId,
          (t) => t.copyWith(
            phase: BuddyTurnPhase.failed,
            failure: failure,
            unavailableCount: unavailable,
          ),
        );
        if (unavailable >= 2) {
          // The text goes back to the composer; a new send is a new message
          // with a new key.
          state = BuddyThread(
            turns: state.turns,
            composerRestore: turn.message.text,
          );
        }
      case BuddyReplyNotSaved():
        _update(
          userMessageId,
          (t) => t.copyWith(
            phase: BuddyTurnPhase.failed,
            failure: BuddySendFailure.rejected,
          ),
        );
    }
  }

  /// Recomputes every other open card's session with a fresh context, so
  /// its "today after this" counts confirmed intake once (D12).
  Future<void> _refreshOthers(String cardId) async {
    final seen = <ProposalSession>{};
    for (final turn in state.turns) {
      for (final card in turn.cards) {
        if (card.id == cardId || !seen.add(card.session)) continue;
        final refreshed = await _resolution.refresh(
          card.session,
          turn.message.time,
        );
        if (!identical(refreshed, card.session)) {
          _replaceSession(
            _turn(turn.userMessageId)!,
            card.session,
            refreshed,
            null,
          );
        }
      }
    }
  }

  CardOrigin _origin(BuddyTurn turn) => CardOrigin(
    interpretation: turn.interpretation ?? const {},
    messageId: turn.assistantMessageId ?? turn.userMessageId,
    referenceTime: turn.message.time,
  );

  BuddyTurn? _turn(String userMessageId) =>
      state.turns.where((t) => t.userMessageId == userMessageId).firstOrNull;

  (BuddyTurn, BuddyCard)? _card(String cardId) {
    for (final turn in state.turns) {
      for (final card in turn.cards) {
        if (card.id == cardId) return (turn, card);
      }
    }
    return null;
  }

  void _update(String userMessageId, BuddyTurn Function(BuddyTurn) change) {
    state = BuddyThread(
      turns: [
        for (final t in state.turns)
          if (t.userMessageId == userMessageId) change(t) else t,
      ],
      composerRestore: state.composerRestore,
    );
  }

  void _setCard(String userMessageId, BuddyCard card) => _update(
    userMessageId,
    (t) => t.copyWith(
      cards: [
        for (final c in t.cards)
          if (c.id == card.id) card else c,
      ],
    ),
  );

  /// Moves every card of [turn] owned by [from] to [to].
  void _replaceSession(
    BuddyTurn turn,
    ProposalSession from,
    ProposalSession to,
    ProposalDiff? diff,
  ) => _update(
    turn.userMessageId,
    (t) => t.copyWith(
      cards: [
        for (final c in t.cards)
          if (identical(c.session, from) &&
              to.cards.any((card) => card.id == c.id))
            c.copyWith(
              session: to,
              diff: diff,
              changeToken: diff == null ? null : Object(),
            )
          else
            c,
      ],
    ),
  );
}
