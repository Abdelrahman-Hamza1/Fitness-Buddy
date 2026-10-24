import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/quick_add/application/quick_add_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_controller.g.dart';

/// Content-free chip refusals.
enum QuickAddFailure {
  /// Shown source changed or disappeared.
  changed,

  /// Invalid source or input.
  invalid,
}

/// Typed result; presentation supplies all wording.
sealed class QuickAddOutcome {
  const new();
}

/// One direct log and Undo.
final class QuickAddLogged extends QuickAddOutcome {
  /// Private display placeholders, never logged. A food carries the
  /// [amount] it was logged with; a saved meal its [itemCount].
  const new(
    this.undoEntryId,
    this.name,
    this.date, {
    this.amount,
    this.itemCount,
  });

  /// Undo handle.
  final String undoEntryId;

  /// Private food or meal name.
  final String name;

  /// Explicit viewed day.
  final LocalDate date;

  /// The amount a food chip logged (the last-used one); null for a meal.
  final EntryAmount? amount;

  /// How many items a saved meal added; null for a food.
  final int? itemCount;
}

/// No second command is sent for an in-flight chip.
final class QuickAddPending extends QuickAddOutcome {
  /// The first command still owns this key.
  const new();
}

/// No write was needed.
final class QuickAddUnchanged extends QuickAddOutcome {
  /// No mutation was applied.
  const new();
}

/// Expected refusal, without private data.
final class QuickAddFailed extends QuickAddOutcome {
  /// Why nothing was logged.
  const new(this.reason);

  /// Content-free reason.
  final QuickAddFailure reason;
}

/// Session-owned commands survive the source day being evicted (D14).
@Riverpod(keepAlive: true)
class QuickAddController extends _$QuickAddController {
  @override
  Set<String> build() => const {};

  /// Uses exactly the rendered choice/guard and context slot.
  Future<QuickAddOutcome> logChip(
    QuickAddChip chip,
    LocalDate viewedDate,
  ) async {
    if (state.contains(chip.key)) return const QuickAddPending();
    state = Set.unmodifiable({...state, chip.key});
    try {
      switch (chip.ranked.candidate) {
        case FoodCandidate(:final lastUsed):
          final choice = chip.choice;
          if (choice == null) {
            return const QuickAddFailed(QuickAddFailure.invalid);
          }
          final result = await ref.read(quickAddLogFoodProvider)(
            choice: choice,
            input: lastUsed.amount.input,
            date: viewedDate,
            slotId: chip.slotId,
          );
          return switch (result) {
            FoodLogged(:final undoEntryId, :final nameEn) => QuickAddLogged(
              undoEntryId,
              nameEn,
              viewedDate,
              amount: lastUsed.amount,
            ),
            FoodLogFailed(:final code) => QuickAddFailed(
              code == 'changed' || code == 'removed'
                  ? QuickAddFailure.changed
                  : QuickAddFailure.invalid,
            ),
          };
        case SavedMealCandidate(:final meal):
          final result = await ref
              .read(savedMealActionsProvider)
              .log(meal, viewedDate, chip.slotId);
          return switch (result) {
            SavedMealDone(:final undoEntryId) => QuickAddLogged(
              undoEntryId,
              meal.name,
              viewedDate,
              itemCount: meal.items.length,
            ),
            SavedMealFailed(:final reason) => QuickAddFailed(
              reason == SavedMealFailure.changed
                  ? QuickAddFailure.changed
                  : QuickAddFailure.invalid,
            ),
            SavedMealPending() => const QuickAddPending(),
            SavedMealUnchanged() => const QuickAddUnchanged(),
          };
      }
    } finally {
      if (ref.mounted) state = Set.unmodifiable(state.difference({chip.key}));
    }
  }
}

/// Session-owned LogFood dependencies for a command that outlives its row.
@Riverpod(keepAlive: true)
LogFood quickAddLogFood(Ref ref) => LogFood(
  apply: ref.watch(diaryApplyProvider),
  undoStack: ref.watch(undoStackProvider),
  clock: ref.watch(clockProvider),
  ids: ref.watch(idGeneratorProvider),
);
