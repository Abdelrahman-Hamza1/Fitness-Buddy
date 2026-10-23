import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';

/// Typed command result; presentation owns all messages and labels.
sealed class LogFoodOutcome {
  const new();
}

/// Successful direct log with its undo handle.
final class FoodLogged extends LogFoodOutcome {
  /// Creates this structured value.
  const new(this.undoEntryId, this.nameEn, this.slotId);

  /// Undo-stack identity returned by the successful apply.
  final String undoEntryId;

  /// English display name.
  final String nameEn;

  /// The selected meal slot; presentation resolves its display label.
  final String? slotId;
}

/// Expected logging failure, represented without display text.
final class FoodLogFailed extends LogFoodOutcome {
  /// Creates this structured value.
  const new(this.code);

  /// Content-free typed failure code for presentation.
  final String code;
}

/// Only the existing applier writes. No text parsing or display formatting.
final class LogFood {
  /// Creates this structured value.
  new({
    required this.apply,
    required this.undoStack,
    required this.clock,
    required this.ids,
  });

  /// The single writer entry point supplied by the composition provider.
  final Future<ApplyResult> Function(ChangeSet) apply;

  /// Records successful direct actions for Undo.
  final UndoStack undoStack;

  /// Injected source of current time and local offset.
  final Clock clock;

  /// Injected ID source for new diary rows.
  final IdGenerator ids;

  /// Logs structured food/input/date/slot data through LogEntries.
  Future<LogFoodOutcome> call({
    required FoodChoice choice,
    required Quantity input,
    required LocalDate date,
    String? slotId,
  }) async {
    if (input.amount <= 0) return const FoodLogFailed('invalidAmount');
    final resolved = choice.measures.resolve(input);
    if (resolved is! Resolved) return const FoodLogFailed('unresolvedAmount');
    final now = EntryTime.now(clock);
    final entry = NewDiaryEntry(
      id: ids.next(),
      when: now.localDate == date ? EntryWhen.at(now) : EntryWhen.onDay(date),
      slotId: slotId,
      food: choice.foodForAmount(resolved),
      amount: EntryAmount(
        input: input,
        amount: resolved.amount,
        basis: resolved.basis,
      ),
    );
    final result = await apply(
      ChangeSet([
        LogEntries([entry]),
      ], origin: Origin.direct),
    );
    if (result is Rejected) return const FoodLogFailed('rejected');
    final undo = undoStack.record(
      result as Applied,
      UndoLabel('foodLogged', args: {'name': choice.names.en}),
    );
    return FoodLogged(undo.id, choice.names.en, slotId);
  }
}
