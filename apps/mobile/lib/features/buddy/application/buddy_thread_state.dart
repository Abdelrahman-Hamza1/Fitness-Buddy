/// The Buddy thread's immutable state (A22 D11, moved out of the
/// controller by A23 rec R1): turns, cards and what a confirm logged.
library;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:fb_mobile/features/buddy/data/buddy_api.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';
import 'package:flutter/foundation.dart' show immutable;

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

  /// Logged, with one Undo while [BuddyCard.undoEntryId] lasts; a
  /// successful Undo opens the card again (A23 D10).
  logged,

  /// Discarded, with one Undo while [BuddyCard.undoEntryId] lasts.
  discarded,

  /// Historical (a synced row another phone marked superseded): read-only,
  /// never confirmable (A21 D9, A23 D13).
  superseded,
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
    this.resolvedFrom,
    this.discardedAt,
    this.rebuilt = false,
  });

  /// The card's ID.
  final String id;

  /// The session that holds the card now.
  final ProposalSession session;

  /// Where it stands.
  final CardResolution resolution;

  /// The undo entry of its confirm or discard, while [resolution] is
  /// logged or discarded.
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

  /// The session before Log it or Discard: what an Undo opens again when
  /// the stored session can't be read back (A23 D10; the database is the
  /// truth whenever it can).
  final ProposalSession? resolvedFrom;

  /// When it was discarded (UTC): Undo lasts the undo window from here.
  final DateTime? discardedAt;

  /// Rebuilt with current food details into its own message (A23 D11): the
  /// turn notes "I updated this card with your current food details."
  final bool rebuilt;

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
    ProposalSession? resolvedFrom,
    DateTime? discardedAt,
    bool? rebuilt,
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
    resolvedFrom: resolvedFrom ?? this.resolvedFrom,
    discardedAt: discardedAt ?? this.discardedAt,
    rebuilt: rebuilt ?? this.rebuilt,
  );

  @override
  String toString() => 'BuddyCard($id, ${resolution.name})';
}

/// A stored card that couldn't be reopened (A23 D13): its session is
/// incomplete or inconsistent, its format unknown, or its kind not a meal.
/// Offered for discard alone. Holds user content: never logged.
@immutable
final class UnrestorableCard {
  /// [record] that failed with [issue].
  const new({
    required this.record,
    required this.issue,
    this.undoEntryId,
    this.discardedAt,
  });

  /// The stored row.
  final ProposalRecord record;

  /// Why it couldn't be reopened (the type alone is reported).
  final ProposalIssue issue;

  /// The undo entry of its discard, once discarded.
  final String? undoEntryId;

  /// When it was discarded (UTC), or `null` while pending.
  final DateTime? discardedAt;

  /// Its row ID.
  String get id => record.id;

  /// Whether it was discarded here.
  bool get discarded => discardedAt != null;

  @override
  String toString() => 'UnrestorableCard($id, ${issue.name})';
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
    this.profileGeneration = 0,
    this.followUpCardId,
    this.unrestorable = const [],
  });

  /// The profile generation the turn was created in (A33 round 4): its
  /// completions and confirms are dropped once the profile switched.
  final int profileGeneration;

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

  /// Stored cards of this turn that couldn't be reopened (A23 D13).
  final List<UnrestorableCard> unrestorable;

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
    List<UnrestorableCard>? unrestorable,
  }) => BuddyTurn(
    message: message,
    request: request ?? this.request,
    phase: phase ?? this.phase,
    failure: failure ?? this.failure,
    unavailableCount: unavailableCount ?? this.unavailableCount,
    assistantMessageId: assistantMessageId ?? this.assistantMessageId,
    interpretation: interpretation ?? this.interpretation,
    cards: cards ?? this.cards,
    profileGeneration: profileGeneration,
    followUpCardId: followUpCardId,
    unrestorable: unrestorable ?? this.unrestorable,
  );

  @override
  String toString() => 'BuddyTurn($userMessageId, ${phase.name})';
}

/// The thread of this app process (D11): turns since launch, oldest first,
/// and text to put back into the composer (after a second 503).
@immutable
final class BuddyThread {
  /// The thread.
  const new({
    this.turns = const [],
    this.composerRestore,
    this.followUpOff,
    this.membership = const SessionMembership(),
    this.orphans = const [],
  });

  /// The turns.
  final List<BuddyTurn> turns;

  /// Which cards left their messages' sessions (A23 D7).
  final SessionMembership membership;

  /// Stored pending cards with no turn to show them in (no or a missing
  /// origin message, A23 D13): shown above the turns, discardable.
  final List<UnrestorableCard> orphans;

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

  /// A copy with [turns] and [membership] replaced and the composer text
  /// kept or cleared ([clearComposer]).
  BuddyThread copyWith({
    List<BuddyTurn>? turns,
    SessionMembership? membership,
    List<UnrestorableCard>? orphans,
    String? composerRestore,
    bool clearComposer = false,
  }) => BuddyThread(
    turns: turns ?? this.turns,
    composerRestore: clearComposer
        ? null
        : composerRestore ?? this.composerRestore,
    followUpOff: followUpOff,
    membership: membership ?? this.membership,
    orphans: orphans ?? this.orphans,
  );

  @override
  String toString() => 'BuddyThread(${turns.length} turns)';
}
