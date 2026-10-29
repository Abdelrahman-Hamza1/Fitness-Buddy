import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/diary_ops.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/workouts/workout_drafts.dart';

/// The op family of workouts (A36 D7). The app's handler turns each op into
/// row writes; sessions and templates are aggregates (the parent row plus its
/// child rows), so one op saves, edits or deletes the whole thing and undo
/// restores it. `toString` never shows names or values.
sealed class WorkoutOp implements ChangeOp {
  const new _();

  /// The [family] of every workout op.
  static const String familyName = 'workout';

  @override
  String get family => familyName;
}

/// Create a custom exercise (WO-003).
final class CreateCustomExercise extends WorkoutOp {
  /// The new row [id] with [draft].
  new(this.id, this.draft) : super._() {
    checkUuid(id, 'id');
  }

  /// The new exercise's ID.
  final String id;

  /// Its content.
  final CustomExerciseDraft draft;

  @override
  bool operator ==(Object other) =>
      other is CreateCustomExercise && other.id == id && other.draft == draft;

  @override
  int get hashCode => Object.hash(CreateCustomExercise, id, draft);

  @override
  String toString() => 'CreateCustomExercise($id)';
}

/// Edit a custom exercise (WO-003). The type can't change once sets exist:
/// the handler rejects it (old sets would no longer fit, WO-004).
final class UpdateCustomExercise extends WorkoutOp {
  /// [exercise] at its shown version gets [draft].
  const new(this.exercise, this.draft) : super._();

  /// The row and the version it must have.
  final VersionedId exercise;

  /// The new content.
  final CustomExerciseDraft draft;

  @override
  bool operator ==(Object other) =>
      other is UpdateCustomExercise &&
      other.exercise == exercise &&
      other.draft == draft;

  @override
  int get hashCode => Object.hash(UpdateCustomExercise, exercise, draft);

  @override
  String toString() => 'UpdateCustomExercise($exercise)';
}

/// Delete a custom exercise (tombstone; undo revives it). Logged sets keep
/// pointing at it, so history stays readable.
final class DeleteCustomExercise extends WorkoutOp {
  /// Delete [exercise] at its shown version.
  const new(this.exercise) : super._();

  /// The row and the version it must have.
  final VersionedId exercise;

  @override
  bool operator ==(Object other) =>
      other is DeleteCustomExercise && other.exercise == exercise;

  @override
  int get hashCode => Object.hash(DeleteCustomExercise, exercise);

  @override
  String toString() => 'DeleteCustomExercise($exercise)';
}

/// Log a session for today or any past date (WO-010, WO-011).
final class LogWorkoutSession extends WorkoutOp {
  /// The new session [id] with [draft].
  new(this.id, this.draft) : super._() {
    checkUuid(id, 'id');
  }

  /// The new session's ID.
  final String id;

  /// The whole session.
  final WorkoutSessionDraft draft;

  @override
  bool operator ==(Object other) =>
      other is LogWorkoutSession && other.id == id && other.draft == draft;

  @override
  int get hashCode => Object.hash(LogWorkoutSession, id, draft);

  @override
  String toString() => 'LogWorkoutSession($id)';
}

/// Replace a session's content. Child rows missing from [draft] become
/// tombstones; new ones are created; kept ones updated in place.
final class UpdateWorkoutSession extends WorkoutOp {
  /// [session] at its shown version gets [draft].
  const new(this.session, this.draft) : super._();

  /// The row and the version it must have.
  final VersionedId session;

  /// The new content.
  final WorkoutSessionDraft draft;

  @override
  bool operator ==(Object other) =>
      other is UpdateWorkoutSession &&
      other.session == session &&
      other.draft == draft;

  @override
  int get hashCode => Object.hash(UpdateWorkoutSession, session, draft);

  @override
  String toString() => 'UpdateWorkoutSession($session)';
}

/// Delete a session with its exercises and sets (tombstones; undo revives).
final class DeleteWorkoutSession extends WorkoutOp {
  /// Delete [session] at its shown version.
  const new(this.session) : super._();

  /// The row and the version it must have.
  final VersionedId session;

  @override
  bool operator ==(Object other) =>
      other is DeleteWorkoutSession && other.session == session;

  @override
  int get hashCode => Object.hash(DeleteWorkoutSession, session);

  @override
  String toString() => 'DeleteWorkoutSession($session)';
}

/// Create a template (WO-020: by form, chat or "save as template").
final class CreateWorkoutTemplate extends WorkoutOp {
  /// The new template [id] with [draft].
  new(this.id, this.draft) : super._() {
    checkUuid(id, 'id');
  }

  /// The new template's ID.
  final String id;

  /// Its content.
  final WorkoutTemplateDraft draft;

  @override
  bool operator ==(Object other) =>
      other is CreateWorkoutTemplate && other.id == id && other.draft == draft;

  @override
  int get hashCode => Object.hash(CreateWorkoutTemplate, id, draft);

  @override
  String toString() => 'CreateWorkoutTemplate($id)';
}

/// Replace a template's content (WO-022: only when the user chooses).
final class UpdateWorkoutTemplate extends WorkoutOp {
  /// [template] at its shown version gets [draft].
  const new(this.template, this.draft) : super._();

  /// The row and the version it must have.
  final VersionedId template;

  /// The new content.
  final WorkoutTemplateDraft draft;

  @override
  bool operator ==(Object other) =>
      other is UpdateWorkoutTemplate &&
      other.template == template &&
      other.draft == draft;

  @override
  int get hashCode => Object.hash(UpdateWorkoutTemplate, template, draft);

  @override
  String toString() => 'UpdateWorkoutTemplate($template)';
}

/// Delete a template (tombstone). Plan days pointing at it become rest days
/// in the same change set; sessions keep their `template_id` for history.
final class DeleteWorkoutTemplate extends WorkoutOp {
  /// Delete [template] at its shown version.
  const new(this.template) : super._();

  /// The row and the version it must have.
  final VersionedId template;

  @override
  bool operator ==(Object other) =>
      other is DeleteWorkoutTemplate && other.template == template;

  @override
  int get hashCode => Object.hash(DeleteWorkoutTemplate, template);

  @override
  String toString() => 'DeleteWorkoutTemplate($template)';
}

/// Set which template a weekday trains, or `null` for rest (WO-021). One
/// row per weekday (natural ID), so two devices editing the same day merge.
final class SetPlanDay extends WorkoutOp {
  /// [weekday] trains [templateId], or rests when `null`.
  new(this.weekday, this.templateId) : super._() {
    if (templateId case final t?) checkUuid(t, 'templateId');
  }

  /// The weekday.
  final DayOfWeek weekday;

  /// The template, or `null` for a rest day.
  final String? templateId;

  @override
  bool operator ==(Object other) =>
      other is SetPlanDay &&
      other.weekday == weekday &&
      other.templateId == templateId;

  @override
  int get hashCode => Object.hash(SetPlanDay, weekday, templateId);

  @override
  String toString() => 'SetPlanDay(${weekday.name})';
}
