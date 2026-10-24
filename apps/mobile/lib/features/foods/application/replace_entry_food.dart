import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/application/log_food.dart';

/// Replaces food and amount on the version shown, retaining location (D7).
final class ReplaceEntryFood {
  /// Uses the same single-writer and undo ports as LogFood.
  const new({required this.apply, required this.undoStack});

  /// The only writer.
  final Future<ApplyResult> Function(ChangeSet) apply;

  /// Direct action undo history.
  final UndoStack undoStack;

  /// Structured input only; no current-version retry on conflict.
  Future<LogFoodOutcome> call(
    VersionedId entry,
    FoodChoice choice,
    Quantity input,
  ) async {
    if (choice.ref.kind == FoodRefKind.personal &&
        (choice.guard == null || choice.guard!.id != choice.ref.id)) {
      return const FoodLogFailed('removed');
    }
    final resolved = choice.measures.resolve(input);
    if (input.amount <= 0 || resolved is! Resolved || resolved.amount <= 0) {
      return const FoodLogFailed('invalidAmount');
    }
    final ApplyResult result;
    try {
      result = await apply(
        ChangeSet([
          if (choice.ref.kind == FoodRefKind.personal)
            RequirePersonalFood(choice.guard!),
          UpdateDiaryEntry(
            entry.id,
            entry.expectedVersion,
            EntryPatch(
              food: choice.foodForAmount(resolved),
              amount: EntryAmount(
                input: input,
                amount: resolved.amount,
                basis: resolved.basis,
              ),
            ),
          ),
        ], origin: Origin.direct),
      );
    } on ChangeRejected catch (rejection) {
      return foodLogFailure(rejection.failure);
    }
    if (result is Rejected) return foodLogFailure(result.failure);
    final undo = undoStack.record(
      result as Applied,
      UndoLabel('foodChanged', args: {'name': choice.names.en}),
    );
    return FoodLogged(undo.id, choice.names.en, null);
  }
}
