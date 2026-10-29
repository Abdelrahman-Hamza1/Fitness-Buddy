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
    required this.undoEntryId,
    required this.undoRefused,
    required this.referenceDate,
  });

  /// The view of [card] in the thread; [referenceDate] is the day of the
  /// message it answers (the day "today" meant when it was sent).
  factory of(BuddyCard card, {LocalDate? referenceDate}) {
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
      undoEntryId: card.undoEntryId,
      undoRefused: card.undoRefused,
      referenceDate: referenceDate,
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

  /// The confirm's undo entry, while Undo is offered.
  final String? undoEntryId;

  /// Why the last Undo wrote nothing.
  final UndoOutcome? undoRefused;

  /// The message's day, when known.
  final LocalDate? referenceDate;

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
  bool get canLog => resolution == CardResolution.open && card.canConfirm;

  /// Some items are estimates, so the totals are too (SF-041, D-045).
  bool get isEstimate => logged?.estimate ?? lines.any((l) => l.isEstimate);

  /// The first issue that blocks Log it.
  ProposalIssue? get blockedBy => card.issues.firstOrNull;

  @override
  String toString() => 'FoodCardView($id)';
}
