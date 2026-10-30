import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Why a line is an estimate, for the range sheet (AI-032).
enum EstimateReason {
  /// A reference dish's typical portion.
  referencePortion,

  /// Buddy's own estimate (no real match).
  buddyEstimate,

  /// The amount was guessed.
  guessedAmount,
}

/// One item of a food card. Holds user content: never logged.
@immutable
final class FoodLineView {
  /// The view of [line].
  const new({required this.line, required this.reason});

  /// The engine's line.
  final ProposalLine line;

  /// Why it's an estimate, when it is one.
  final EstimateReason? reason;

  /// The line's (and its diary row's) ID.
  String get id => line.entry.id;

  /// The food.
  EntryFood get food => line.entry.food;

  /// The amount as typed and its canonical value.
  EntryAmount get amount => line.entry.amount;

  /// Shown with `~` and a range (AI-032).
  bool get isEstimate =>
      line.range != null || line.entry.food.provenance.isEstimate;

  /// The stored assumption codes behind the line (`a1:` codes).
  List<String> get assumptions => line.entry.food.provenance.assumptions;

  /// Buddy assumed the amount: the card shows − / + (A22b E3).
  bool get amountAssumed => line.amountAssumed;

  /// A generated component (the assumed oil) of the line [componentOf];
  /// swiping it removes only it.
  String? get componentOf => line.componentOf;

  /// Other foods it could be (AI-041).
  List<ProposalFood> get alternatives => line.alternatives;

  /// The unit codes the inline pad offers (AI-040): as typed, the basis
  /// unit (grams or millilitres) and the food's own servings.
  List<String> get editUnits => {
    amount.input.unitCode,
    if (amount.basis == NutrientBasis.per100ml)
      VolumeUnit.milliliter.code
    else
      MassUnit.gram.code,
    for (final s in line.selectedFood?.servings ?? const <ProposalServing>[])
      s.code,
  }.toList();
}

/// A selected assumption the card shows as a chip (AI-033): the line it
/// belongs to, its dimension and the selected option.
@immutable
final class FoodChipView {
  /// The chip.
  const new({
    required this.lineId,
    required this.foodName,
    required this.dimension,
    required this.selected,
    required this.origin,
  });

  /// The line it belongs to.
  final String lineId;

  /// The line's food name, for the question and option words.
  final String foodName;

  /// The dimension.
  final ProposalDimension dimension;

  /// The selected option.
  final ProposalOption selected;

  /// Where the selection came from.
  final ProposalChoiceOrigin origin;
}

/// An in-card question with its answers (AI-034): the default first.
@immutable
final class FoodQuestionView {
  /// The question.
  const new({
    required this.foodName,
    required this.dimension,
    required this.options,
    required this.selectedOptionId,
    required this.defaultOptionId,
  });

  /// The line's food name.
  final String foodName;

  /// The dimension asked about.
  final ProposalDimension dimension;

  /// The answers, in the question's order.
  final List<ProposalOption> options;

  /// The selected answer.
  final String? selectedOptionId;

  /// The answer assumed when the user doesn't pick (labelled).
  final String defaultOptionId;
}

/// Everything a food proposal card shows (A22 D13), built from the engine's
/// card, its message's question budget and the last diff. Typed: the
/// presentation layer turns it into words.
@immutable
final class FoodCardView {
  const new _({
    required this.card,
    required this.resolution,
    required this.lines,
    required this.assumptions,
    required this.questions,
    required this.dishName,
    required this.changedLineIds,
    required this.totalsChanged,
    required this.changeToken,
    required this.couldNotLog,
    required this.logged,
    required this.removed,
    required this.discardUndoFrom,
    required this.undoEntryId,
    required this.undoRefused,
    required this.referenceDate,
    required this.updating,
    required this.rebuilt,
    required this.tooLargeToSync,
    required this.canUpdate,
  });

  /// The view of [card] in the thread; [referenceDate] is the day of the
  /// message it answers (the day "today" meant when it was sent).
  factory of(
    BuddyCard card, {
    LocalDate? referenceDate,
    bool updating = false,
    Map<String, Object?>? turnAnswer,
  }) {
    final proposal = card.card;
    final asked = {for (final q in card.budget.questions) q.dimensionId: q};
    final lines = <FoodLineView>[];
    final chips = <FoodChipView>[];
    final questions = <FoodQuestionView>[];
    for (final line in proposal.lines) {
      final name = line.entry.food.names.en;
      final selected = {for (final c in line.chips) c.dimensionId: c};
      lines.add(FoodLineView(line: line, reason: _reason(line)));
      for (final dimension in line.dimensions) {
        final chip = selected[dimension.id];
        final question = asked[dimension.id];
        if (question != null) {
          final options = [
            for (final id in question.optionIds)
              ?dimension.options.where((o) => o.id == id).firstOrNull,
          ];
          if (options.length < 2) continue;
          questions.add(
            FoodQuestionView(
              foodName: name,
              dimension: dimension,
              options: options,
              selectedOptionId: chip?.optionId,
              defaultOptionId: options.first.id,
            ),
          );
        } else if (chip != null) {
          final option = dimension.options
              .where((o) => o.id == chip.optionId)
              .firstOrNull;
          if (option == null) continue;
          chips.add(
            FoodChipView(
              lineId: line.entry.id,
              foodName: name,
              dimension: dimension,
              selected: option,
              origin: chip.origin,
            ),
          );
        }
      }
    }
    final diff = card.diff;
    final changed = <String>{
      ...?diff?.addedLineIds,
      for (final MapEntry(:key, :value)
          in diff?.lineFields.entries ??
              const <MapEntry<String, Set<ProposalField>>>[])
        if (value.isNotEmpty) key,
    };
    return FoodCardView._(
      card: proposal,
      resolution: card.resolution,
      lines: lines,
      assumptions: chips,
      questions: questions,
      dishName: proposal.draftOps
          .whereType<CreateDishGroup>()
          .firstOrNull
          ?.name,
      changedLineIds: changed,
      totalsChanged:
          changed.isNotEmpty ||
          (diff?.removedLineIds.isNotEmpty ?? false) ||
          (diff?.cardFields[proposal.id]?.isNotEmpty ?? false),
      changeToken: card.changeToken,
      couldNotLog: card.couldNotLog,
      logged: card.logged,
      removed: card.removed,
      discardUndoFrom: card.undoEntryId == null ? null : card.discardedAt,
      undoEntryId: card.undoEntryId,
      undoRefused: card.undoRefused,
      referenceDate: referenceDate,
      updating: updating,
      rebuilt: card.rebuilt,
      // A23 D15: kept on this phone; the mapper parks it for sync.
      tooLargeToSync:
          card.resolution == CardResolution.open &&
          ProposalDraftCodec.syncProjection(card.session, card.id).issue ==
              ProposalIssue.syncPayloadTooLarge,
      canUpdate:
          (card.origin?.interpretation ?? turnAnswer)?.isNotEmpty ?? false,
    );
  }

  static EstimateReason? _reason(ProposalLine line) {
    final provenance = line.entry.food.provenance;
    if (line.range == null && !provenance.isEstimate) return null;
    return switch (provenance.source) {
      FoodSource.reference => EstimateReason.referencePortion,
      FoodSource.estimate => EstimateReason.buddyEstimate,
      _ => EstimateReason.guessedAmount,
    };
  }

  /// The engine's card.
  final ProposalCard card;

  /// Where it stands in the thread.
  final CardResolution resolution;

  /// The items.
  final List<FoodLineView> lines;

  /// Assumption chips (selected options not asked about).
  final List<FoodChipView> assumptions;

  /// In-card questions.
  final List<FoodQuestionView> questions;

  /// The dish name, when the items form one dish.
  final String? dishName;

  /// Lines the last change touched (UX-024).
  final Set<String> changedLineIds;

  /// Whether the totals changed with it.
  final bool totalsChanged;

  /// A fresh token per change.
  final Object? changeToken;

  /// The last Log it wrote nothing ("Couldn't log this card.").
  final bool couldNotLog;

  /// What was logged.
  final LoggedSummary? logged;

  /// Lines swiped away, for "Removed … · Undo" (AI-042).
  final List<RemovedLine> removed;

  /// When it was discarded, while its Undo is offered (#142); null when a
  /// discard can't be undone.
  final DateTime? discardUndoFrom;

  /// The confirm's undo entry, while Undo is offered.
  final String? undoEntryId;

  /// Why the last Undo wrote nothing.
  final UndoOutcome? undoRefused;

  /// The message's day, when known.
  final LocalDate? referenceDate;

  /// A follow-up about this card is in flight: it's read-only until the
  /// answer arrives ("Updating…", A22b review 1).
  final bool updating;

  /// Rebuilt with the current food details into its own message (A23 D11):
  /// the note says so.
  final bool rebuilt;

  /// Too large to sync to other phones (A23 D15): the note says how to fix
  /// it.
  final bool tooLargeToSync;

  /// Its answer is stored, so a stale card can be updated offline (A23
  /// D13).
  final bool canUpdate;

  /// Its food details changed since it was made (a reopened card, A23 D13):
  /// read-only, "Update card" or Discard.
  bool get factsChanged => card.issues.any(
    (i) => i == ProposalIssue.staleFacts || i == ProposalIssue.factsMismatch,
  );

  /// The day it would be logged to (or was).
  LocalDate get date => logged?.preview.date ?? card.preview.date;

  /// It's for another day than the message's (a day hint, B09 D8): the card
  /// says which.
  bool get otherDay => referenceDate != null && date != referenceDate;

  /// The card's ID.
  String get id => card.id;

  /// When it would be logged, from its first line.
  EntryTime? get time => switch (card.lines.firstOrNull?.entry.when) {
    EntryAt(:final time) => time,
    _ => null,
  };

  /// The meal it would be logged to.
  String? get slotId => card.lines.firstOrNull?.entry.slotId;

  /// Totals at storage precision.
  Nutrients get totals => card.totals;

  /// The day with this card counted once (AI-031).
  ProposalDayPreview get preview => card.preview;

  /// Log it is offered (an open card that can be confirmed).
  bool get canLog =>
      resolution == CardResolution.open && !updating && card.canConfirm;

  /// Some items are estimates, so the totals are too (SF-041, D-045).
  bool get isEstimate => logged?.estimate ?? lines.any((l) => l.isEstimate);

  /// The first issue that blocks Log it.
  ProposalIssue? get blockedBy => card.issues.firstOrNull;

  @override
  String toString() => 'FoodCardView($id)';
}
