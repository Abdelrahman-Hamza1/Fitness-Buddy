import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/workouts/data/workout_op_handler.dart'
    show planDayId;
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_actions.g.dart';

/// Why a workout action wrote nothing (content-free).
enum WorkoutActionFailure {
  /// The row changed since it was shown.
  changed,

  /// The row is gone.
  removed,

  /// Sessions or templates use the exercise (D15: delete only while
  /// unused; the type is locked once sets exist).
  inUse,

  /// The op was refused otherwise.
  invalid,
}

/// What a workout action did.
@immutable
sealed class WorkoutActionOutcome {
  const new _();
}

/// Written; [undoId] undoes it. [id] is the row's ID.
final class WorkoutActionDone extends WorkoutActionOutcome {
  /// Done.
  const new(this.undoId, this.id) : super._();

  /// The undo entry.
  final String undoId;

  /// The row written.
  final String id;
}

/// Nothing differed: nothing written.
final class WorkoutActionUnchanged extends WorkoutActionOutcome {
  /// Unchanged.
  const new() : super._();
}

/// Refused: nothing written.
final class WorkoutActionFailed extends WorkoutActionOutcome {
  /// Refused because of [reason].
  const new(this.reason) : super._();

  /// Why.
  final WorkoutActionFailure reason;
}

/// Undo label keys of workout actions (the screens map them to ARB).
abstract final class WorkoutActionLabels {
  /// A custom exercise was created.
  static const String exerciseCreated = 'customExerciseCreated';

  /// A custom exercise was edited.
  static const String exerciseUpdated = 'customExerciseUpdated';

  /// A custom exercise was deleted.
  static const String exerciseDeleted = 'customExerciseDeleted';

  /// A template was created.
  static const String templateCreated = 'templateCreated';

  /// A template was edited.
  static const String templateUpdated = 'templateUpdated';

  /// A template was deleted.
  static const String templateDeleted = 'templateDeleted';

  /// A weekday's plan changed.
  static const String planDaySet = 'planDaySet';

  /// A starter plan was copied.
  static const String starterPlanApplied = 'starterPlanApplied';

  /// The weekly plan was cleared ("No plan", D-089).
  static const String planCleared = 'planCleared';
}

/// Direct workout actions with undo (WO-003, D15), through the single
/// writer.
final class WorkoutActions {
  /// Writing with [apply], undo in [undoStack], new IDs from [ids].
  new({
    required this.apply,
    required this.undoStack,
    required this.ids,
    required this.repository,
  });

  /// The applier's `apply`.
  final Future<ApplyResult> Function(ChangeSet) apply;

  /// Where undo entries go.
  final UndoStack undoStack;

  /// New row IDs.
  final IdGenerator ids;

  /// Reads references (D15).
  final WorkoutRepository repository;

  /// Creates a custom exercise.
  Future<WorkoutActionOutcome> createExercise(CustomExerciseDraft draft) {
    final id = ids.next();
    return _run(
      [CreateCustomExercise(id, draft)],
      WorkoutActionLabels.exerciseCreated,
      id,
    );
  }

  /// Edits [exercise] (the type can't change while sets use it).
  Future<WorkoutActionOutcome> updateExercise(
    Stored<CustomExerciseDraft> exercise,
    CustomExerciseDraft draft,
  ) {
    if (draft == exercise.draft) {
      return Future.value(const WorkoutActionUnchanged());
    }
    return _run(
      [UpdateCustomExercise(exercise.ref, draft)],
      WorkoutActionLabels.exerciseUpdated,
      exercise.ref.id,
    );
  }

  /// Deletes [exercise], only while no live session or template uses it
  /// (D15). This check gives instant feedback; the handler checks again
  /// inside the write transaction.
  Future<WorkoutActionOutcome> deleteExercise(
    Stored<CustomExerciseDraft> exercise,
  ) async {
    final used = await repository.watchExerciseReferences().first;
    if (used.contains(exercise.ref.id)) {
      return const WorkoutActionFailed(WorkoutActionFailure.inUse);
    }
    return await _run(
      [DeleteCustomExercise(exercise.ref)],
      WorkoutActionLabels.exerciseDeleted,
      exercise.ref.id,
    );
  }

  /// Saves a template (A37 D17: an explicit Save with its normal undo): a
  /// new one when [template] is `null`, else an edit of it.
  Future<WorkoutActionOutcome> saveTemplate(
    Stored<WorkoutTemplateDraft>? template,
    WorkoutTemplateDraft draft,
  ) {
    if (template == null) {
      final id = ids.next();
      return _run(
        [CreateWorkoutTemplate(id, draft)],
        WorkoutActionLabels.templateCreated,
        id,
      );
    }
    if (draft == template.draft) {
      return Future.value(const WorkoutActionUnchanged());
    }
    return _run(
      [UpdateWorkoutTemplate(template.ref, draft)],
      WorkoutActionLabels.templateUpdated,
      template.ref.id,
    );
  }

  /// Deletes [template]; plan days using it become rest days in the same
  /// change set, sessions keep pointing at it (A36). Undo restores both.
  Future<WorkoutActionOutcome> deleteTemplate(
    Stored<WorkoutTemplateDraft> template,
  ) => _run(
    [DeleteWorkoutTemplate(template.ref)],
    WorkoutActionLabels.templateDeleted,
    template.ref.id,
  );

  /// [weekday] trains [templateId], or rests when `null` (WO-021).
  Future<WorkoutActionOutcome> setPlanDay(
    DayOfWeek weekday,
    String? templateId,
  ) => _run(
    [SetPlanDay(weekday, templateId)],
    WorkoutActionLabels.planDaySet,
    planDayId(weekday),
  );

  /// Creates [plan]'s templates with the exercises the user chose
  /// ([itemsOf], D-089: never assumed) and assigns them to [days] (every
  /// other day rests) in **one** change set (A37 D18, PA4): all of it or
  /// nothing, one undo. Templates are named by [nameOf]; existing templates
  /// stay.
  Future<WorkoutActionOutcome> applyStarterPlan(
    StarterPlan plan, {
    required Iterable<DayOfWeek> days,
    required DayOfWeek weekStart,
    required String Function(StarterTemplate template) nameOf,
    required List<TemplateTarget> Function(StarterTemplate template) itemsOf,
  }) {
    final ops = plan.ops(
      days: days,
      weekStart: weekStart,
      ids: ids,
      nameOf: nameOf,
      itemsOf: itemsOf,
    );
    return _run(
      ops,
      WorkoutActionLabels.starterPlanApplied,
      ops.whereType<CreateWorkoutTemplate>().first.id,
    );
  }

  /// Makes every weekday a rest day in one change set with one undo ("No
  /// plan, I'll log as I go", D-089). Templates stay.
  Future<WorkoutActionOutcome> clearPlan() => _run(
    [for (final day in DayOfWeek.values) SetPlanDay(day, null)],
    WorkoutActionLabels.planCleared,
    planDayId(DayOfWeek.monday),
  );

  Future<WorkoutActionOutcome> _run(
    List<ChangeOp> ops,
    String label,
    String id,
  ) async {
    final result = await apply(ChangeSet(ops, origin: Origin.direct));
    switch (result) {
      case Applied(:final inverse) when inverse.isEmpty:
        return const WorkoutActionUnchanged();
      case Applied():
        return WorkoutActionDone(
          undoStack.record(result, UndoLabel(label)).id,
          id,
        );
      case Rejected(:final failure):
        return WorkoutActionFailed(switch (failure) {
          VersionConflict() => WorkoutActionFailure.changed,
          RowNotFound() => WorkoutActionFailure.removed,
          InvalidOp(code: 'typeInUse' || 'exerciseInUse') =>
            WorkoutActionFailure.inUse,
          _ => WorkoutActionFailure.invalid,
        });
    }
  }
}

/// The workout actions.
@Riverpod(keepAlive: true)
WorkoutActions workoutActions(Ref ref) => WorkoutActions(
  apply: ref.watch(changeSetApplierProvider).apply,
  undoStack: ref.watch(undoStackProvider),
  ids: ref.watch(idGeneratorProvider),
  repository: ref.watch(workoutRepositoryProvider),
);
