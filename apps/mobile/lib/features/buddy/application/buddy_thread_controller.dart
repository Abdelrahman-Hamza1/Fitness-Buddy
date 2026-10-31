import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_reply_texts.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_restorer.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_state.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/application/proposal_write_lane.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:fb_mobile/features/buddy/data/buddy_api.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/foods/foods.dart' show FoodChoice;
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:fb_mobile/features/buddy/application/buddy_thread_state.dart';
export 'package:fb_mobile/features/buddy/data/buddy_api.dart'
    show BuddySendFailure;

part 'buddy_thread_controller.g.dart';

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

  /// The thread's one serial write lane (A23 D7, D8): replies, follow-ups,
  /// coalesced adjustments, confirms, discards, rebuilds and undos run here
  /// one after another, each from the latest sessions. New per generation.
  ProposalWriteLane _lane = ProposalWriteLane();

  /// Messages whose session one or more Undos are reverting, with how many:
  /// their cards take no adjustment until the last one is done, so no edit
  /// is lost to a reopened session (A23 D10).
  /// New per generation: an older generation's undo releases only its own.
  Map<String, int> _undoing = {};

  /// This generation's restore, once started (A23 D12: idempotent).
  Future<void>? _restored;

  /// Whether the app is past its first frame (the bootstrap restored the
  /// first generation): later generations restore from [build].
  bool _started = false;

  /// The profile generation this thread belongs to (A33 round 4).
  int _generation = 0;

  /// Whether work started in generation [gen] may still change the thread.
  bool _current(int gen) => ref.mounted && gen == _generation;

  @override
  BuddyThread build() {
    // A profile switch rebuilds the thread empty: no text, card or confirm
    // crosses profiles (A33 round 4).
    _generation = ref.watch(profileGenerationProvider);
    _saving = false;
    _lane = ProposalWriteLane();
    _undoing = {};
    _restored = null;
    if (_started) {
      // A profile switch after the first frame: this profile's cards come
      // back too (A23 D12).
      final gen = _generation;
      unawaited(Future.microtask(() => ensureRestored(gen)));
    }
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
    // A34 D17 (A23 handoff): rows pulled from another phone can add or
    // resolve cards; read this profile's pending cards back again (merged
    // by message ID, a turn in memory wins).
    final remote = ref
        .read(domainEventBusProvider)
        .on<RemoteChangesApplied>()
        .where(
          (e) =>
              e.entities.contains('chatMessage') ||
              e.entities.contains('proposal'),
        )
        .listen((_) => unawaited(_restoreAgain()));
    ref
      ..onDispose(changes.cancel)
      ..onDispose(remote.cancel);
    return const BuddyThread();
  }

  Future<void> _refreshOpenCards() async {
    final gen = _generation;
    final open = state.turns.any(
      (t) => t.cards.any((c) => c.resolution == CardResolution.open),
    );
    if (open) await _refreshOthersSafely('', gen);
  }

  /// Reads this profile's pending cards back into the thread once per
  /// [generation] (A23 D12): after the first frame, the catalog install and
  /// account recovery. Every session with a pending card returns, merged by
  /// message ID (a turn already in memory wins). Never before the first
  /// frame; a stale generation's restore is dropped.
  Future<void> ensureRestored(int generation) {
    _started = true;
    if (!ref.mounted || generation != _generation) return Future.value();
    return _restored ??= _restore(generation);
  }

  /// Re-runs the restore after a remote apply, once the first restore of
  /// this generation ran (never before the first frame).
  Future<void> _restoreAgain() {
    if (!_started || !ref.mounted) return Future.value();
    final gen = _generation;
    return _restored = (_restored ?? Future.value()).then(
      (_) => _current(gen) ? _restore(gen) : Future.value(),
    );
  }

  Future<void> _restore(int gen) async {
    try {
      final restorer = ref.read(buddyThreadRestorerProvider);
      final lane = _lane;
      await lane.run(() async {
        final restored = await restorer.restore(generation: gen);
        if (!_current(gen)) return;
        final live = {for (final t in state.turns) t.userMessageId};
        final liveCards = {
          for (final t in state.turns) ...t.cards.map((c) => c.id),
        };
        final added = [
          for (final t in restored.turns)
            if (!live.contains(t.userMessageId))
              t.copyWith(
                cards: [
                  for (final c in t.cards)
                    if (!liveCards.contains(c.id)) c,
                ],
              ),
        ];
        final turns = [...state.turns, ...added]
          ..sort((a, b) {
            final at = a.message.time.occurredAtUtc;
            final bt = b.message.time.occurredAtUtc;
            return at != bt
                ? at.compareTo(bt)
                : a.userMessageId.compareTo(b.userMessageId);
          });
        final shown = {for (final o in state.orphans) o.id};
        state = state.copyWith(
          turns: turns,
          membership: state.membership.merge(restored.membership),
          orphans: [
            ...state.orphans,
            for (final o in restored.orphans)
              if (!shown.contains(o.id)) o,
          ],
        );
      });
      // A restore that fails leaves the thread as it is; cards come back on
      // the next generation or launch.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  SendBuddyMessage get _send => ref.read(sendBuddyMessageProvider);

  ProposalResolution get _resolution => ref.read(proposalResolutionProvider);

  /// Saves [raw], shows the turn at once (skeleton), then interprets it.
  /// Ignored while a send is in flight or for blank text.
  Future<void> send(String raw, BuddyReplyTexts texts) async {
    if (state.sending || _saving) return;
    final gen = _generation;
    // The use case of this generation (its applier is bound to it).
    final send = _send;
    _saving = true;
    SavedBuddyMessage? message;
    try {
      message = await send.save(raw);
    } on Object {
      message = null;
    } finally {
      if (_current(gen)) _saving = false;
    }
    if (!_current(gen)) return;
    if (message == null) {
      // Not persisted (e.g. the write gate refused during an account
      // transition): the text goes back to the composer (A33 re-check 4).
      if (raw.trim().isNotEmpty && ref.mounted) {
        state = state.copyWith(composerRestore: raw);
      }
      return;
    }
    // A message sent while a card is open updates that card (AI-044).
    final target = state.followUpCard;
    state = state.copyWith(
      turns: [
        ...state.turns,
        BuddyTurn(
          message: message,
          profileGeneration: gen,
          followUpCardId: target?.id,
        ),
      ],
      clearComposer: true,
    );
    try {
      final request = await send.prepare(message, followUp: target?.card);
      if (!_current(gen)) return;
      _update(message.id, (t) => t.copyWith(request: request));
      await _dispatch(message.id, texts, gen);
      // A throw must never leave the turn "sending" (Send stays disabled
      // forever): it fails as a server error, retryable when the request
      // was prepared (A22a review). Nothing of it is logged.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      if (_current(gen)) _failed(message.id);
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
    final gen = _generation;
    if (turn.profileGeneration != gen) return;
    _update(userMessageId, (t) => t.copyWith(phase: BuddyTurnPhase.sending));
    try {
      await _dispatch(userMessageId, texts, gen);
      // See [send].
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      if (_current(gen)) _failed(userMessageId);
    }
  }

  /// The composer's text to restore, once (then cleared).
  String? takeComposerRestore() {
    final text = state.composerRestore;
    if (text != null) {
      state = state.copyWith(clearComposer: true);
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
      membership: state.membership,
      orphans: state.orphans,
    );
  }

  /// Applies a chip/answer [adjustment] to open card [cardId] and recomputes
  /// its session; nothing is written (AI-033, AI-034, AI-036).
  void adjust(String cardId, ProposalAdjustment adjustment) {
    final found = _card(cardId);
    if (found == null ||
        found.$2.resolution != CardResolution.open ||
        state.isUpdating(cardId) ||
        _undoing.containsKey(SessionMembership.messageOf(found.$2.session))) {
      return;
    }
    final update = ProposalEngine.recompute(found.$2.session, adjustment).value;
    if (update == null) return;
    // A coalesced latest-wins write, flushed on dismiss, pause, or before a
    // confirm or discard (A23 D8).
    if (!update.diff.isEmpty) {
      if (SessionMembership.messageOf(update.session) case final message?) {
        _lane.schedule(message);
      }
    }
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
  /// Runs as a lane job from the card's latest session, after any pending
  /// adjustment write (A23 D7, D8).
  Future<void> confirm(String cardId) async {
    final found = _card(cardId);
    if (found == null) return;
    final (turn, card) = found;
    if (card.resolution != CardResolution.open ||
        !card.card.canConfirm ||
        state.isUpdating(cardId)) {
      return;
    }
    final gen = _generation;
    if (turn.profileGeneration != gen) return;
    // The use cases and lane of this generation (A33).
    final resolution = _resolution;
    final lane = _lane;
    _setCard(
      turn.userMessageId,
      card.copyWith(resolution: CardResolution.confirming, couldNotLog: false),
    );
    var logged = false;
    try {
      await lane.run(() async {
        await lane.drain(_writeLatest(resolution, gen));
        final latest = _card(cardId)?.$2;
        if (!_current(gen) || latest == null) return;
        final before = latest.card;
        final outcome = await resolution.confirm(
          latest.session,
          cardId,
          latest.origin ?? _origin(turn),
          membership: state.membership,
        );
        if (!_current(gen)) return;
        logged = _onConfirmed(turn, latest, before, outcome);
      });
      // A throw never leaves the card "confirming": it's open again with
      // "Couldn't log this card." (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      if (!_current(gen)) return;
      final now = _card(cardId)?.$2;
      if (now != null && now.resolution == CardResolution.confirming) {
        _setCard(
          turn.userMessageId,
          now.copyWith(resolution: CardResolution.open, couldNotLog: true),
        );
      }
      return;
    }
    if (logged && _current(gen)) await _refreshOthersSafely(cardId, gen);
  }

  /// The thread after confirm [outcome] of [card] (whose card was
  /// [before]); whether it was logged.
  bool _onConfirmed(
    BuddyTurn turn,
    BuddyCard card,
    ProposalCard before,
    ConfirmOutcome outcome,
  ) {
    final cardId = card.id;
    switch (outcome) {
      case CardLogged(:final session, :final undoEntryId, :final appliedAt):
        // The day as it is now, from the refreshed session (confirmed
        // intake with this card in it), not the card's pre-confirm preview.
        final after =
            session.cards.where((c) => c.id == cardId).firstOrNull?.preview ??
            before.preview;
        _replaceSession(
          turn,
          _card(cardId)!.$2.session,
          _rebased(card.session, session, cardId, ProposalLifecycle.confirmed),
          null,
        );
        _setCard(
          turn.userMessageId,
          _card(cardId)!.$2.copyWith(
            resolution: CardResolution.logged,
            undoEntryId: undoEntryId,
            resolvedFrom: card.session,
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
        return true;
      case CardRebuilt(
        :final session,
        :final messageId,
        :final from,
        :final interpretation,
      ):
        // Rebuilt with current facts into its own message (A23 D11).
        if (messageId != null && from != null) {
          state = state.copyWith(
            membership: state.membership.rebuilt(cardId, from),
          );
        }
        final origin = card.origin ?? _origin(turn);
        _setCard(
          turn.userMessageId,
          BuddyCard(
            id: cardId,
            session: session,
            removed: card.removed,
            rebuilt: messageId != null,
            origin: messageId == null
                ? card.origin
                : CardOrigin(
                    interpretation: interpretation ?? origin.interpretation,
                    messageId: messageId,
                    referenceTime: origin.referenceTime,
                  ),
          ),
        );
        return false;
      case CardNotLogged():
        _setCard(
          turn.userMessageId,
          _card(cardId)!.$2
              .copyWith(resolution: CardResolution.open, couldNotLog: true),
        );
        return false;
    }
  }

  /// The session to show after [cardId] was resolved to [lifecycle] from
  /// [from] (giving [resolved]): when a sibling was adjusted meanwhile
  /// (the shared session moved on), the resolution is applied to that newer
  /// session instead, so neither is lost (A23 D7, PA1); its pending write
  /// stores both.
  ProposalSession _rebased(
    ProposalSession from,
    ProposalSession resolved,
    String cardId,
    ProposalLifecycle lifecycle,
  ) {
    final current = _card(cardId)?.$2.session;
    if (current == null || identical(current, from)) return resolved;
    return ProposalEngine.recompute(
          current,
          ProposalSetLifecycle(cardId, lifecycle),
        ).value?.session ??
        resolved;
  }

  /// Writes a message's latest session whole (a coalesced job, A23 D7):
  /// `false` when it was refused (a newer stored revision).
  Future<bool> Function(String) _writeLatest(
    ProposalResolution resolution,
    int gen,
  ) => (messageId) async {
    if (!_current(gen)) return false;
    final session = _latestSession(messageId);
    if (session == null) return true;
    return await resolution.persist(session, state.membership);
  };

  /// The newest in-memory session of message [messageId], if any card
  /// shows it.
  ProposalSession? _latestSession(String messageId) {
    for (final turn in state.turns) {
      for (final card in turn.cards) {
        if (SessionMembership.messageOf(card.session) == messageId) {
          return card.session;
        }
      }
    }
    return null;
  }

  /// Writes every adjusted session now (A23 D8): when the sheet is
  /// dismissed or the app pauses.
  Future<void> flush() async {
    // Nothing adjusted: no write, and no use case is even read.
    if (!_lane.hasPending) return;
    final gen = _generation;
    try {
      await _lane.flush(_writeLatest(_resolution, gen));
      // Bookkeeping only; the next change schedules the write again.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Discards open card [cardId]; nothing is logged (AI-037). The discard is
  /// one undoable change set (A23 D10), a lane job like a confirm.
  Future<void> discard(String cardId) async {
    final found = _card(cardId);
    if (found == null ||
        found.$2.resolution != CardResolution.open ||
        state.isUpdating(cardId)) {
      return;
    }
    final gen = _generation;
    if (found.$1.profileGeneration != gen) return;
    final resolution = _resolution;
    final lane = _lane;
    final clock = ref.read(clockProvider);
    try {
      await lane.run(() async {
        await lane.drain(_writeLatest(resolution, gen));
        final latest = _card(cardId)?.$2;
        if (!_current(gen) ||
            latest == null ||
            latest.resolution != CardResolution.open) {
          return;
        }
        final outcome = await resolution.discard(
          latest.session,
          cardId,
          membership: state.membership,
        );
        if (outcome == null || !_current(gen)) return;
        final turn = _turn(found.$1.userMessageId)!;
        _replaceSession(
          turn,
          _card(cardId)!.$2.session,
          _rebased(
            latest.session,
            outcome.session,
            cardId,
            ProposalLifecycle.discarded,
          ),
          null,
        );
        _setCard(
          turn.userMessageId,
          _card(cardId)!.$2.copyWith(
            resolution: CardResolution.discarded,
            undoEntryId: outcome.undoEntryId,
            resolvedFrom: latest.session,
            discardedAt: outcome.appliedAt ?? clock.nowUtc(),
          ),
        );
      });
      // A throw leaves the card open (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return;
    }
  }

  /// Rebuilds stale restored card [cardId] with the current food details
  /// from its stored answer, offline, into its own message (A23 D11, D13:
  /// "Update card"). Nothing happens without a stored answer.
  Future<void> updateCard(String cardId) async {
    final found = _card(cardId);
    if (found == null ||
        found.$2.resolution != CardResolution.open ||
        found.$1.profileGeneration != _generation) {
      return;
    }
    final gen = _generation;
    final resolution = _resolution;
    final lane = _lane;
    try {
      await lane.run(() async {
        await lane.drain(_writeLatest(resolution, gen));
        final latest = _card(cardId);
        if (!_current(gen) || latest == null) return;
        final origin = latest.$2.origin ?? _origin(latest.$1);
        if (origin.interpretation.isEmpty) return;
        final rebuilt = await resolution.rebuild(
          latest.$2.session,
          cardId,
          origin,
          membership: state.membership,
        );
        if (!_current(gen) || rebuilt == null) return;
        _onConfirmed(latest.$1, latest.$2, latest.$2.card, rebuilt);
      });
      // A failure leaves the card as it is.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Discards stored card [recordId] that couldn't be reopened (A23 D13):
  /// its row alone, undoable.
  Future<void> discardUnrestorable(String recordId) async {
    final found = _unrestorable(recordId);
    if (found == null || found.$2.discarded) return;
    final gen = _generation;
    final resolution = _resolution;
    try {
      await _lane.run(() async {
        final done = await resolution.discardRecord(found.$2.record);
        if (done == null || !_current(gen)) return;
        _setUnrestorable(
          found.$1,
          UnrestorableCard(
            record: found.$2.record,
            issue: found.$2.issue,
            undoEntryId: done.$1,
            discardedAt: done.$2,
          ),
        );
      });
      // A failure leaves the placeholder as it is.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Undoes the discard of placeholder [recordId].
  Future<void> restoreUnrestorable(String recordId) async {
    final found = _unrestorable(recordId);
    final entry = found?.$2.undoEntryId;
    if (found == null || entry == null) return;
    final gen = _generation;
    final resolution = _resolution;
    try {
      await _lane.run(() async {
        final outcome = await resolution.undo(entry);
        if (!_current(gen)) return;
        _setUnrestorable(
          found.$1,
          UnrestorableCard(
            record: found.$2.record,
            issue: found.$2.issue,
            discardedAt: outcome == UndoOutcome.undone
                ? null
                : found.$2.discardedAt,
          ),
        );
      });
      // A failure leaves the placeholder discarded.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }

  /// Placeholder [recordId] and the turn that shows it (`null` for an
  /// orphan shown above the turns).
  (BuddyTurn?, UnrestorableCard)? _unrestorable(String recordId) {
    for (final card in state.orphans) {
      if (card.id == recordId) return (null, card);
    }
    for (final turn in state.turns) {
      for (final card in turn.unrestorable) {
        if (card.id == recordId) return (turn, card);
      }
    }
    return null;
  }

  void _setUnrestorable(BuddyTurn? turn, UnrestorableCard card) {
    List<UnrestorableCard> swap(List<UnrestorableCard> cards) => [
      for (final c in cards)
        if (c.id == card.id) card else c,
    ];
    if (turn == null) {
      state = state.copyWith(orphans: swap(state.orphans));
    } else {
      _update(
        turn.userMessageId,
        (t) => t.copyWith(unrestorable: swap(t.unrestorable)),
      );
    }
  }

  /// Undoes the Discard of [cardId] (backlog #142, A23 D10): its change set
  /// is reverted and the card opens again as stored.
  Future<UndoOutcome?> restoreDiscarded(String cardId) =>
      _undoResolution(cardId, CardResolution.discarded);

  /// Undoes logged card [cardId] once (D25, A23 D10): the whole confirm is
  /// reverted and the card opens again with Log it, read back from the
  /// database. Refused (a row changed since, or too late): it stays logged.
  Future<UndoOutcome?> undo(String cardId) =>
      _undoResolution(cardId, CardResolution.logged);

  Future<UndoOutcome?> _undoResolution(
    String cardId,
    CardResolution resolved,
  ) async {
    final found = _card(cardId);
    final entry = found?.$2.undoEntryId;
    if (found == null ||
        entry == null ||
        found.$2.resolution != resolved ||
        found.$1.profileGeneration != _generation) {
      return null;
    }
    final gen = _generation;
    // The use cases and lane of this generation (A33).
    final resolution = _resolution;
    final restorer = ref.read(buddyThreadRestorerProvider);
    final lane = _lane;
    final message = SessionMembership.messageOf(
      found.$2.resolvedFrom ?? found.$2.session,
    );
    final undoing = _undoing;
    if (message != null) {
      undoing.update(message, (n) => n + 1, ifAbsent: () => 1);
    }
    try {
      final outcome = await lane.run(
        () => _revert(cardId, entry, found.$1, resolution, restorer, lane, gen),
      );
      if (outcome == UndoOutcome.undone && _current(gen)) {
        await _refreshOthersSafely(cardId, gen);
      }
      return outcome;
      // A throw leaves the card resolved with its Undo (A22a review).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    } finally {
      if (message != null) {
        final left = (undoing[message] ?? 0) - 1;
        if (left > 0) {
          undoing[message] = left;
        } else {
          undoing.remove(message);
        }
      }
    }
  }

  /// The lane job of an Undo: the revert, then the card read back.
  Future<UndoOutcome?> _revert(
    String cardId,
    String entry,
    BuddyTurn found,
    ProposalResolution resolution,
    BuddyThreadRestorer restorer,
    ProposalWriteLane lane,
    int gen,
  ) async {
    // A stale generation's undo touches no lane, its own or the new one's.
    if (!_current(gen)) return null;
    // Any adjustment made since is written first, so a sibling changed
    // after the resolve makes the revert refuse (A23 D7, D10).
    await lane.drain(_writeLatest(resolution, gen));
    if (!_current(gen)) return null;
    final outcome = await resolution.undo(entry);
    if (!_current(gen)) return null;
    final now = _card(cardId)!.$2;
    if (outcome != UndoOutcome.undone) {
      _setCard(
        found.userMessageId,
        BuddyCard(
          id: cardId,
          session: now.session,
          diff: now.diff,
          logged: now.logged,
          resolution: now.resolution,
          undoRefused: outcome,
          origin: now.origin,
          discardedAt: now.discardedAt,
          rebuilt: now.rebuilt,
        ),
      );
      return outcome;
    }
    // The database is the truth after a revert: the card's session as
    // stored now (the card pending again).
    final message = SessionMembership.messageOf(
      now.resolvedFrom ?? now.session,
    );
    ProposalSession? stored;
    if (message != null) {
      stored = (await restorer.session(
        message,
        referenceTime: found.message.time,
      )).value;
    }
    if (!_current(gen)) return outcome;
    // The stored rows equal the session before the resolve (it was written
    // first): when their facts can't be verified here (a food not in this
    // phone's pack), that in-memory session reopens instead.
    bool confirmable(ProposalSession? s) =>
        s?.cards.any((c) => c.id == cardId && c.canConfirm) ?? false;
    final reopened = confirmable(stored) || now.resolvedFrom == null
        ? stored
        : now.resolvedFrom;
    final turn = _turn(found.userMessageId)!;
    if (reopened != null &&
        reopened.cards.any(
          (c) => c.id == cardId && c.lifecycle == ProposalLifecycle.active,
        )) {
      _replaceSession(turn, now.session, reopened, null);
      _setCard(
        turn.userMessageId,
        BuddyCard(
          id: cardId,
          session: reopened,
          origin: now.origin,
          removed: now.removed,
          rebuilt: now.rebuilt,
        ),
      );
    }
    return outcome;
  }

  /// [_refreshOthers], where a failure only leaves sibling previews as they
  /// were: the logged card and its Undo are already shown.
  Future<void> _refreshOthersSafely(String cardId, int gen) async {
    try {
      await _refreshOthers(cardId, gen);
      // Any failure here is only a stale preview.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // Previews refresh on the next change.
    }
  }

  Future<void> _dispatch(
    String userMessageId,
    BuddyReplyTexts texts,
    int gen,
  ) async {
    if (!_current(gen)) return;
    final turn = _turn(userMessageId)!;
    final send = _send;
    final lane = _lane;
    final followUpId = turn.followUpCardId;
    await send.dispatch(
      turn.message,
      turn.request!,
      texts,
      // Read when the answer is saved, from the latest thread (A23 D7).
      followUp: followUpId == null ? null : () => _followUpState(followUpId),
      // The save and the thread update are one lane job, so no later job
      // reads the thread before it.
      lane: (save) => lane.run(() async {
        final reply = await save();
        _onReply(userMessageId, turn, reply, gen);
        return reply;
      }),
    );
  }

  /// Where follow-up card [cardId] stands now: open (its latest session and
  /// membership) or closed, logged or discarded before this (retried)
  /// follow-up: the card is left alone and the reply says so, never
  /// "Updated" (review 7).
  FollowUpState _followUpState(String cardId) {
    final target = _card(cardId);
    if (target == null) return (target: null, closed: false);
    if (target.$2.resolution != CardResolution.open) {
      return (target: null, closed: true);
    }
    return (
      target: FollowUpTarget(
        card: target.$2.card,
        session: target.$2.session,
        referenceTime: target.$1.message.time,
        membership: state.membership,
      ),
      closed: false,
    );
  }

  /// The thread after [reply] to [turn] (inside the lane job that saved
  /// it).
  void _onReply(
    String userMessageId,
    BuddyTurn turn,
    BuddyReply reply,
    int gen,
  ) {
    // A reply that arrives after a profile switch is dropped (A33 round 4).
    if (!_current(gen)) return;
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
        // highlighted (UX-024); it moved to the follow-up's message (A23
        // D7).
        final cardId = session.cards.single.id;
        final now = _card(cardId);
        if (now != null && now.$2.resolution == CardResolution.open) {
          state = state.copyWith(
            membership: state.membership.followedUp(
              cardId,
              now.$2.card.budgetMessageId,
              assistantMessageId,
            ),
          );
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
                referenceTime: now.$1.message.time,
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
          state = state.copyWith(composerRestore: turn.message.text);
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
  Future<void> _refreshOthers(String cardId, int gen) async {
    final seen = <ProposalSession>{};
    for (final turn in state.turns) {
      for (final card in turn.cards) {
        if (card.id == cardId || !seen.add(card.session)) continue;
        final refreshed = await _resolution.refresh(
          card.session,
          turn.message.time,
        );
        if (!_current(gen)) return;
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
    state = state.copyWith(
      turns: [
        for (final t in state.turns)
          if (t.userMessageId == userMessageId) change(t) else t,
      ],
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
