import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/data/buddy_api.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/foods/foods.dart' show FoodChoice;
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
    this.origin,
    this.removed = const [],
    this.discardedFrom,
    this.discardedAt,
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

  /// Where the card comes from since a follow-up rebuilt it (the follow-up's
  /// answer and assistant row); `null`: its turn's.
  final CardOrigin? origin;

  /// Lines swiped away, newest last, each with its food name for the inline
  /// "Removed … · Undo" (AI-042, A22b E6).
  final List<RemovedLine> removed;

  /// The session before Discard, so its Undo can put the card back (in
  /// memory: a discard writes nothing in A22b, E8).
  final ProposalSession? discardedFrom;

  /// When it was discarded (UTC): Undo lasts the undo window from here.
  final DateTime? discardedAt;

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
    CardOrigin? origin,
    List<RemovedLine>? removed,
    ProposalSession? discardedFrom,
    DateTime? discardedAt,
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
    origin: origin ?? this.origin,
    removed: removed ?? this.removed,
    discardedFrom: discardedFrom ?? this.discardedFrom,
    discardedAt: discardedAt ?? this.discardedAt,
  );

  @override
  String toString() => 'BuddyCard($id, ${resolution.name})';
}

/// A line swiped off an open card: its ID and food name (for "Removed … ·
/// Undo"). Holds user content: never logged.
@immutable
final class RemovedLine {
  /// Line [id] of food [name].
  const new(this.id, this.name);

  /// The line's ID.
  final String id;

  /// The food's name.
  final String name;

  @override
  String toString() => 'RemovedLine($id)';
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
    this.followUpCardId,
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

  /// The open card this message follows up on (AI-044), when it does.
  final String? followUpCardId;

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
    followUpCardId: followUpCardId,
  );

  @override
  String toString() => 'BuddyTurn($userMessageId, ${phase.name})';
}

/// The thread of this app process (D11): turns since launch, oldest first,
/// and text to put back into the composer (after a second 503).
@immutable
final class BuddyThread {
  /// The thread.
  const new({this.turns = const [], this.composerRestore, this.followUpOff});

  /// The turns.
  final List<BuddyTurn> turns;

  /// Text the composer should take back, once.
  final String? composerRestore;

  /// The open card the user said the next message isn't about (✕ on the
  /// follow-up chip, D21).
  final String? followUpOff;

  /// Whether a follow-up about card [cardId] is in flight: the card is
  /// read-only until its answer arrives, so the answer never overwrites an
  /// edit made meanwhile (A22b review 1).
  bool isUpdating(String cardId) => turns.any(
    (t) => t.phase == BuddyTurnPhase.sending && t.followUpCardId == cardId,
  );

  /// The card the next message updates (AI-044, A22b E2): the newest open
  /// card, unless the user turned it off.
  BuddyCard? get followUpCard {
    for (final turn in turns.reversed) {
      for (final card in turn.cards.reversed) {
        if (card.resolution == CardResolution.open) {
          return card.id == followUpOff ? null : card;
        }
      }
    }
    return null;
  }

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
    // A message sent while a card is open updates that card (AI-044).
    final target = state.followUpCard;
    state = BuddyThread(
      turns: [
        ...state.turns,
        BuddyTurn(message: message, followUpCardId: target?.id),
      ],
      followUpOff: state.followUpOff,
    );
    try {
      final request = await _send.prepare(message, followUp: target?.card);
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
    if (text != null) {
      state = BuddyThread(turns: state.turns, followUpOff: state.followUpOff);
    }
    return text;
  }

  /// The next message starts a new card instead of updating the open one
  /// (✕ on the follow-up chip, D21).
  void clearFollowUp() {
    final card = state.followUpCard;
    if (card == null) return;
    state = BuddyThread(
      turns: state.turns,
      composerRestore: state.composerRestore,
      followUpOff: card.id,
    );
  }

  /// Applies a chip/answer [adjustment] to open card [cardId] and recomputes
  /// its session; nothing is written (AI-033, AI-034, AI-036).
  void adjust(String cardId, ProposalAdjustment adjustment) {
    final found = _card(cardId);
    if (found == null ||
        found.$2.resolution != CardResolution.open ||
        state.isUpdating(cardId)) {
      return;
    }
    final update = ProposalEngine.recompute(found.$2.session, adjustment).value;
    if (update == null) return;
    _replaceSession(found.$1, found.$2.session, update.session, update.diff);
  }

  /// − / + on an assumed amount (AI-040, A22b E3): the next amount from
  /// [AmountStep], recomputed by the engine. Nothing is written.
  void stepAmount(String cardId, String lineId, {required bool up}) {
    final line = _line(cardId, lineId);
    if (line == null) return;
    final current = line.entry.amount.input;
    final next = up ? AmountStep.up(current) : AmountStep.down(current);
    if (next == null) return;
    adjust(cardId, ProposalSetAmount(lineId, next));
  }

  /// Sets line [lineId]'s amount to [quantity] from the inline number pad
  /// and unit chips (AI-040); the engine recomputes. Nothing is written.
  void setAmount(String cardId, String lineId, Quantity quantity) {
    if (quantity.amount <= 0 || _line(cardId, lineId) == null) return;
    adjust(cardId, ProposalSetAmount(lineId, quantity));
  }

  /// Swaps line [lineId]'s food for [food] (an alternative or a food picked
  /// in search, AI-041).
  void swapFood(String cardId, String lineId, ProposalFood food) {
    if (_line(cardId, lineId) == null) return;
    adjust(cardId, ProposalSwap(lineId, food));
  }

  /// Adds [food] at [quantity] to open card [cardId] ("Add item", AI-042):
  /// a new line with its own ID, computed by the engine.
  void addFood(String cardId, ProposalFood food, Quantity quantity) {
    if (quantity.amount <= 0) return;
    final ids = ref.read(idGeneratorProvider);
    adjust(
      cardId,
      ProposalAdd(
        cardId,
        ids.next(),
        ProposalItem(
          id: 'add',
          displayName: food.names.en,
          match: food,
          quantity: quantity,
          explicit: true,
          alternatives: const [],
          dimensions: const [],
        ),
        GeneratorProposalIds(ids),
      ),
    );
  }

  /// Swaps line [lineId] for the food [choice] picked in food search
  /// (AI-041); a choice that's neither a catalog nor a personal food
  /// changes nothing.
  void swapPicked(String cardId, String lineId, FoodChoice choice) {
    final food = ProposalInputLoader.proposalFoodOf(choice);
    if (food != null) swapFood(cardId, lineId, food);
  }

  /// Adds the food [choice] picked in food search at [quantity] (AI-042).
  void addPicked(String cardId, FoodChoice choice, Quantity quantity) {
    final food = ProposalInputLoader.proposalFoodOf(choice);
    if (food != null) addFood(cardId, food, quantity);
  }

  /// Swipes line [lineId] off open card [cardId] (AI-042); the card offers
  /// "Removed … · Undo" ([restoreLine]).
  void removeLine(String cardId, String lineId) {
    final line = _line(cardId, lineId);
    if (line == null) return;
    adjust(cardId, ProposalSetRemoved(lineId, removed: true));
    final found = _card(cardId);
    if (found == null || found.$2.card.lines.any((l) => l.entry.id == lineId)) {
      return;
    }
    _setCard(
      found.$1.userMessageId,
      found.$2.copyWith(
        removed: [
          ...found.$2.removed,
          RemovedLine(lineId, line.entry.food.names.en),
        ],
      ),
    );
  }

  /// Puts back a line removed from open card [cardId].
  void restoreLine(String cardId, String lineId) {
    final found = _card(cardId);
    if (found == null || !found.$2.removed.any((r) => r.id == lineId)) return;
    adjust(cardId, ProposalSetRemoved(lineId, removed: false));
    final now = _card(cardId);
    if (now == null || !now.$2.card.lines.any((l) => l.entry.id == lineId)) {
      return;
    }
    _setCard(
      now.$1.userMessageId,
      now.$2.copyWith(
        removed: [
          for (final r in now.$2.removed)
            if (r.id != lineId) r,
        ],
      ),
    );
  }

  /// Moves open card [cardId] to meal [slotId] (AI-043).
  void setSlot(String cardId, String slotId) =>
      adjust(cardId, ProposalSetWhen(cardId, slotId: slotId));

  /// Moves open card [cardId] to [time] on its day, in its own offset
  /// (AI-043).
  void setTime(String cardId, LocalTime time) {
    final found = _card(cardId);
    final when = found?.$2.card.lines.firstOrNull?.entry.when;
    if (when is! EntryAt) return;
    final current = when.time;
    adjust(
      cardId,
      ProposalSetWhen(
        cardId,
        time: EntryTime.local(time.on(current.localDate), current.tzOffsetMin),
      ),
    );
  }

  ProposalLine? _line(String cardId, String lineId) =>
      _card(cardId)?.$2.card.lines
          .where((l) => l.entry.id == lineId)
          .firstOrNull;

  /// Logs card [cardId] (one tap, UX-003). Single-flight: a second call
  /// while one applies, or for a card that can't be confirmed, does nothing.
  Future<void> confirm(String cardId) async {
    final found = _card(cardId);
    if (found == null) return;
    final (turn, card) = found;
    if (card.resolution != CardResolution.open ||
        !card.card.canConfirm ||
        state.isUpdating(cardId)) {
      return;
    }
    final before = card.card;
    _setCard(
      turn.userMessageId,
      card.copyWith(resolution: CardResolution.confirming, couldNotLog: false),
    );
    final ConfirmOutcome outcome;
    try {
      outcome = await _resolution.confirm(
        card.session,
        cardId,
        card.origin ?? _origin(turn),
      );
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
        _setCard(
          turn.userMessageId,
          BuddyCard(id: cardId, session: session, origin: card.origin),
        );
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
    if (found == null ||
        found.$2.resolution != CardResolution.open ||
        state.isUpdating(cardId)) {
      return;
    }
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
      _card(cardId)!.$2.copyWith(
        resolution: CardResolution.discarded,
        // Undo only while a discard writes nothing (no contributor ops; A23
        // adds a resolve-undo before it registers any, E8).
        discardedFrom: _resolution.discardUndoable ? found.$2.session : null,
        discardedAt: ref.read(clockProvider).nowUtc(),
      ),
    );
  }

  /// Undoes the Discard of [cardId] (backlog #142): the card is open again
  /// as it was, with "today after this" refreshed. Nothing is written.
  Future<void> restoreDiscarded(String cardId) async {
    final found = _card(cardId);
    final before = found?.$2.discardedFrom;
    if (found == null ||
        before == null ||
        found.$2.resolution != CardResolution.discarded) {
      return;
    }
    _setCard(
      found.$1.userMessageId,
      BuddyCard(
        id: cardId,
        session: before,
        origin: found.$2.origin,
        removed: found.$2.removed,
      ),
    );
    await _refreshOpenCards();
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
    final target = switch (turn.followUpCardId) {
      final id? => _card(id),
      null => null,
    };
    final followUp =
        target == null || target.$2.resolution != CardResolution.open
        ? null
        : FollowUpTarget(
            card: target.$2.card,
            referenceTime: target.$1.message.time,
          );
    final reply = await _send.dispatch(
      turn.message,
      turn.request!,
      texts,
      followUp: followUp,
      // Logged or discarded before this (retried) follow-up: the card is
      // left alone and the reply says so, never "Updated" (review 7).
      followUpClosed: target != null && followUp == null,
    );
    switch (reply) {
      case BuddyFollowedUp(
        :final assistantMessageId,
        :final session,
        :final diff,
        :final interpretation,
      ):
        _update(
          userMessageId,
          (t) => t.copyWith(
            phase: BuddyTurnPhase.replied,
            assistantMessageId: assistantMessageId,
            interpretation: interpretation,
          ),
        );
        // The card stays where it is, rebuilt with the same ID and
        // highlighted (UX-024). Logged or discarded meanwhile: left alone.
        final now = _card(followUp!.card.id);
        if (now != null && now.$2.resolution == CardResolution.open) {
          _setCard(
            now.$1.userMessageId,
            BuddyCard(
              id: now.$2.id,
              session: session,
              diff: diff,
              changeToken: Object(),
              removed: now.$2.removed,
              origin: CardOrigin(
                interpretation: interpretation,
                messageId: assistantMessageId,
                referenceTime: followUp.referenceTime,
              ),
            ),
          );
        }
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
            followUpOff: state.followUpOff,
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
      followUpOff: state.followUpOff,
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
