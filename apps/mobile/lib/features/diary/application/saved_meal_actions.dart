import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/application/diary_actions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_meal_actions.g.dart';

/// Content-free expected refusals; presentation owns the wording.
enum SavedMealFailure {
  /// The shown source changed or disappeared.
  changed,

  /// Invalid input or an empty source.
  invalid,
}

/// Direct-action Undo label keys.
enum SavedMealKind {
  /// All copied entries form one Undo.
  savedMealLogged,

  /// Parent renamed.
  savedMealRenamed,

  /// Parent and live items deleted.
  savedMealDeleted,
}

/// Structured command result, never display text.
sealed class SavedMealOutcome {
  const new();
}

/// One completed direct action.
final class SavedMealDone extends SavedMealOutcome {
  /// Private placeholders are passed only to presentation and Undo.
  const new(this.undoEntryId, this.kind, this.args);

  /// Undo handle.
  final String undoEntryId;

  /// Label key.
  final SavedMealKind kind;

  /// Private display placeholders; never log.
  final Map<String, Object> args;
}

/// No mutation was necessary.
final class SavedMealUnchanged extends SavedMealOutcome {
  /// Identical rename or no-op apply.
  const new();
}

/// A duplicate command was dropped.
final class SavedMealPending extends SavedMealOutcome {
  /// No second apply is started.
  const new();
}

/// Expected rejection with no partial write.
final class SavedMealFailed extends SavedMealOutcome {
  /// Content-free reason.
  const new(this.reason);

  /// Why the action was refused.
  final SavedMealFailure reason;
}

/// Calls only A09a's existing guarded operations, through the single writer.
final class SavedMealActions {
  /// Dependencies are explicit for deterministic race and Undo tests.
  new({
    required this.apply,
    required this.undoStack,
    required this.ids,
    required this.clock,
  });

  /// Single writer port.
  final Future<ApplyResult> Function(ChangeSet) apply;

  /// Session Undo history.
  final UndoStack undoStack;

  /// New entry identities.
  final IdGenerator ids;

  /// Current time and local zone.
  final Clock clock;
  final Set<String> _pending = {};

  /// Copies exactly the shown parent and item versions (D19).
  Future<SavedMealOutcome> log(SavedMeal meal, LocalDate date, String slotId) {
    final versions = meal.versions;
    if (versions == null) {
      return Future.value(const SavedMealFailed(SavedMealFailure.invalid));
    }
    return _run(
      meal.id,
      () {
        final now = EntryTime.now(clock);
        return LogSavedMeal(
          expected: versions,
          entryIds: {for (final item in meal.items) item.id: ids.next()},
          when: date == now.localDate
              ? EntryWhen.at(now)
              : EntryWhen.onDay(date),
          slotId: slotId,
        );
      },
      SavedMealKind.savedMealLogged,
      {'name': meal.name, 'date': date},
    );
  }

  /// Renames the observed version; an untouched name writes nothing.
  Future<SavedMealOutcome> rename(SavedMeal meal, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60 || trimmed.contains('\u0000')) {
      return Future.value(const SavedMealFailed(SavedMealFailure.invalid));
    }
    if (trimmed == meal.name) return Future.value(const SavedMealUnchanged());
    return _run(
      meal.id,
      () => RenameSavedMeal(meal.id, meal.version, trimmed),
      SavedMealKind.savedMealRenamed,
      {'name': trimmed},
    );
  }

  /// Deletes the shown parent version and its current items atomically.
  Future<SavedMealOutcome> delete(SavedMeal meal) => _run(
    meal.id,
    () => DeleteSavedMeal(meal.id, meal.version),
    SavedMealKind.savedMealDeleted,
    {'name': meal.name},
  );

  SavedMealFailed _failure(ChangeFailure failure) =>
      SavedMealFailed(switch (failure) {
        VersionConflict() ||
        RowNotFound() ||
        InvalidOp(code: 'sourceChanged') ||
        InvalidOp(code: 'emptySource') => SavedMealFailure.changed,
        _ => SavedMealFailure.invalid,
      });

  Future<SavedMealOutcome> _run(
    String key,
    DiaryOp Function() op,
    SavedMealKind kind,
    Map<String, Object> args,
  ) async {
    if (!_pending.add(key)) return const SavedMealPending();
    try {
      final ApplyResult result;
      try {
        result = await apply(ChangeSet([op()], origin: Origin.direct));
      } on ChangeRejected catch (rejection) {
        return _failure(rejection.failure);
      }
      if (result is Rejected) return _failure(result.failure);
      final applied = result as Applied;
      if (applied.inverse.isEmpty) return const SavedMealUnchanged();
      final undo = undoStack.record(applied, UndoLabel(kind.name, args: args));
      return SavedMealDone(undo.id, kind, Map.unmodifiable(args));
    } finally {
      _pending.remove(key);
    }
  }
}

/// Session-owned pending commands survive route disposal.
@Riverpod(keepAlive: true)
SavedMealActions savedMealActions(Ref ref) => SavedMealActions(
  apply: ref.watch(diaryApplyProvider),
  undoStack: ref.watch(undoStackProvider),
  ids: ref.watch(idGeneratorProvider),
  clock: ref.watch(clockProvider),
);
