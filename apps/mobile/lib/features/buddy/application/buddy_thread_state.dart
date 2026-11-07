/// The Buddy thread's immutable state (A22 D11, moved out of the
/// controller by A23 rec R1): turns, cards and what a confirm logged.
library;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/proposal_resolution.dart';
import 'package:fb_mobile/features/buddy/application/send_buddy_message.dart';
import 'package:fb_mobile/features/buddy/application/session_membership.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Where a turn stands (A66).
enum BuddyTurnPhase {
  /// Saved; the turn is running (live step line, AI-030, AI-170).
  sending,

  /// Waiting to be processed: offline or Buddy unavailable (AI-047,
  /// AI-153); it runs again on its own.
  pending,

  /// It failed for good ([BuddyTurn.limited] for today's limit): Try
  /// again sends the text as a new message.
  failed,

  /// Buddy answered (the turn ended; its reply row is saved).
  replied,
}

/// One step of a turn's dev trace (AI-172), as shown: local only, never
/// synced or logged.
@immutable
final class TraceStepView {
  /// A step.
  const new({
    required this.tool,
    required this.args,
    required this.resultSummary,
    required this.ms,
    required this.tokens,
    required this.usd,
  });

  /// The tool.
  final String tool;

  /// Its arguments, summarised by the server.
  final String args;

  /// What came back, summarised.
  final String resultSummary;

  /// Milliseconds.
  final int ms;

  /// Tokens.
  final int tokens;

  /// Estimated cost, USD.
  final double usd;

  /// The JSON form (kept with the reply on this phone).
  Map<String, Object?> toJson() => {
    'tool': tool,
    'args': args,
    'resultSummary': resultSummary,
    'ms': ms,
    'tokens': tokens,
    'usd': usd,
  };

  @override
  String toString() => 'TraceStepView($tool)';
}

/// A question Buddy asked with 2–4 chips (AI-166): a tap is the next
/// message. Holds model text: never logged.
@immutable
final class BuddyQuestion {
  /// A question.
  const new(this.text, this.options);

  /// The question.
  final String text;

  /// The chips.
  final List<String> options;

  @override
  String toString() => 'BuddyQuestion(${options.length})';
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
    this.revision = 1,
    this.possibleDuplicate = false,
    this.changedMeanwhile = false,
  });

  /// The card's revision as the phone shows it (A66 D6): an agent update
  /// must name it; a local adjustment raises it.
  final int revision;

  /// Its food, meal and amount match a card confirmed earlier in the same
  /// turn (06 §3.4): "possible duplicate".
  final bool possibleDuplicate;

  /// Buddy's update arrived after the card changed here and was dropped
  /// (AI-044: "changed meanwhile").
  final bool changedMeanwhile;

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
    int? revision,
    bool? possibleDuplicate,
    bool? changedMeanwhile,
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
    revision: revision ?? this.revision,
    possibleDuplicate: possibleDuplicate ?? this.possibleDuplicate,
    changedMeanwhile: changedMeanwhile ?? this.changedMeanwhile,
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

/// A line swiped off an open card: its ID and food names (for "Removed … ·
/// Undo", in the "Food names" setting, LC-007). In memory only. Holds user
/// content: never logged.
@immutable
final class RemovedLine {
  /// Line [id] of food [names].
  const new(this.id, this.names);

  /// The line's ID.
  final String id;

  /// The food's names; presentation picks the setting's one.
  final FoodNames names;

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
    this.phase = BuddyTurnPhase.sending,
    this.limited = false,
    this.assistantMessageId,
    this.interpretation,
    this.cards = const [],
    this.profileGeneration = 0,
    this.unrestorable = const [],
    this.step,
    this.replyText = '',
    this.question,
    this.trace = const [],
    this.unsupported = false,
  });

  /// The profile generation the turn was created in (A33 round 4): its
  /// completions and confirms are dropped once the profile switched.
  final int profileGeneration;

  /// The saved user message.
  final SavedBuddyMessage message;

  /// Where the turn stands.
  final BuddyTurnPhase phase;

  /// It failed on today's limit (429).
  final bool limited;

  /// The reply row, once replied.
  final String? assistantMessageId;

  /// A restored A23-era answer, kept to rebuild a card with current facts.
  final Map<String, Object?>? interpretation;

  /// The cards, in order.
  final List<BuddyCard> cards;

  /// Stored cards of this turn that couldn't be reopened (A23 D13).
  final List<UnrestorableCard> unrestorable;

  /// The live step's wire code while it runs (AI-170).
  final String? step;

  /// The reply text so far (streamed, AI-170).
  final String replyText;

  /// The question Buddy asked, with chips (AI-166).
  final BuddyQuestion? question;

  /// The dev trace of the turn (AI-172; local only).
  final List<TraceStepView> trace;

  /// Buddy proposed something this version can't show yet (A67–A69).
  final bool unsupported;

  /// The user row's ID (the turn ID).
  String get userMessageId => message.id;

  /// The cards Apply all would log (AI-162): two or more open cards of
  /// this reply that can be confirmed.
  List<BuddyCard> get applicable => [
    for (final c in cards)
      if (c.resolution == CardResolution.open && c.card.canConfirm) c,
  ];

  /// A copy with the given fields replaced.
  BuddyTurn copyWith({
    BuddyTurnPhase? phase,
    bool? limited,
    String? assistantMessageId,
    Map<String, Object?>? interpretation,
    List<BuddyCard>? cards,
    List<UnrestorableCard>? unrestorable,
    String? step,
    bool clearStep = false,
    String? replyText,
    BuddyQuestion? question,
    List<TraceStepView>? trace,
    bool? unsupported,
  }) => BuddyTurn(
    message: message,
    phase: phase ?? this.phase,
    limited: limited ?? this.limited,
    assistantMessageId: assistantMessageId ?? this.assistantMessageId,
    interpretation: interpretation ?? this.interpretation,
    cards: cards ?? this.cards,
    profileGeneration: profileGeneration,
    unrestorable: unrestorable ?? this.unrestorable,
    step: clearStep ? null : step ?? this.step,
    replyText: replyText ?? this.replyText,
    question: question ?? this.question,
    trace: trace ?? this.trace,
    unsupported: unsupported ?? this.unsupported,
  );

  @override
  String toString() => 'BuddyTurn($userMessageId, ${phase.name})';
}

/// The thread of this app process (D11): turns since launch and restored
/// ones, oldest first, and text to put back into the composer.
@immutable
final class BuddyThread {
  /// The thread.
  const new({
    this.turns = const [],
    this.composerRestore,
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

  /// Whether a turn is running (Send disabled; one turn at a time).
  bool get sending => turns.any((t) => t.phase == BuddyTurnPhase.sending);

  /// Messages waiting to be processed (Today's "{n} waiting", AI-045).
  int get waiting =>
      turns.where((t) => t.phase == BuddyTurnPhase.pending).length;

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
    membership: membership ?? this.membership,
    orphans: orphans ?? this.orphans,
  );

  @override
  String toString() => 'BuddyThread(${turns.length} turns)';
}
