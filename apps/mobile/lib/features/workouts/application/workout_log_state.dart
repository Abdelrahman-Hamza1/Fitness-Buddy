import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/workouts/application/set_input.dart';
import 'package:fb_mobile/features/workouts/data/workout_repository.dart';
import 'package:flutter/foundation.dart' show immutable;

/// How the log form was opened (A37 D13, D14).
@immutable
sealed class LogLaunch {
  const new _();
}

/// A new session: with the [exercises] just picked, a Repeat of
/// [repeatOf], or started from template [templateId] (A37c D20). [visitId]
/// makes each visit its own form.
final class NewLog extends LogLaunch {
  /// A new session on [date] (clamped to today), one per [visitId].
  new({
    required this.visitId,
    required this.date,
    this.repeatOf,
    this.templateId,
    Iterable<String> exercises = const [],
  }) : exercises = List.unmodifiable(exercises),
       super._();

  /// Unique per visit.
  final String visitId;

  /// The training day (WO-011: past allowed, never the future).
  final LocalDate date;

  /// The session to repeat (WO-024), or `null`.
  final String? repeatOf;

  /// The template to start from (WO-020), or `null`. Ignored by a Repeat.
  final String? templateId;

  /// The picked exercises, in order (ignored by a Repeat or a template).
  final List<String> exercises;

  @override
  bool operator ==(Object other) =>
      other is NewLog &&
      other.visitId == visitId &&
      other.date == date &&
      other.repeatOf == repeatOf &&
      other.templateId == templateId &&
      other.exercises.join(',') == exercises.join(',');

  @override
  int get hashCode => Object.hash(
    NewLog,
    visitId,
    date,
    repeatOf,
    templateId,
    Object.hashAll(exercises),
  );

  @override
  String toString() => 'NewLog($visitId)';
}

/// An existing session, opened to view or edit (D14), one form per
/// [visitId].
final class EditLog extends LogLaunch {
  /// Session [sessionId].
  const new(this.sessionId, {required this.visitId}) : super._();

  /// The session.
  final String sessionId;

  /// Unique per visit.
  final String visitId;

  @override
  bool operator ==(Object other) =>
      other is EditLog &&
      other.sessionId == sessionId &&
      other.visitId == visitId;

  @override
  int get hashCode => Object.hash(EditLog, sessionId, visitId);

  @override
  String toString() => 'EditLog($sessionId)';
}

/// One set row of the form (D7).
@immutable
final class LogSetRow {
  /// Row [id].
  const new({
    required this.id,
    this.input = const SetInput(),
    this.hint,
    this.checked = false,
    this.saved,
    this.issue,
  });

  /// The set row's stable ID.
  final String id;

  /// What's typed.
  final SetInput input;

  /// Last time's numbers for this set ("80 × 8"), or `null`.
  final SetValues? hint;

  /// Whether the set is done; only checked sets are saved (D8).
  final bool checked;

  /// The last valid values (what autosave writes while [checked]).
  final LoggedSet? saved;

  /// Why the typed values don't fit, shown as a field error; `null` when
  /// they do (or nothing is typed).
  final WorkoutSetIssue? issue;

  /// This row with some fields changed ([issue] is always replaced).
  LogSetRow copyWith({
    SetInput? input,
    bool? checked,
    LoggedSet? saved,
    WorkoutSetIssue? issue,
  }) => LogSetRow(
    id: id,
    input: input ?? this.input,
    hint: hint,
    checked: checked ?? this.checked,
    saved: saved ?? this.saved,
    issue: issue,
  );

  /// The domain view of this row.
  LogFormSet toFormSet() => LogFormSet(id: id, checked: checked, value: saved);
}

/// One exercise card of the form, in form order.
@immutable
final class LogExerciseCard {
  /// Card [id] (the session-exercise row ID) of [exerciseId].
  new({
    required this.id,
    required this.exerciseId,
    required Iterable<LogSetRow> sets,
  }) : sets = List.unmodifiable(sets);

  /// The session-exercise row's stable ID.
  final String id;

  /// A catalog ID or a custom exercise's UUID.
  final String exerciseId;

  /// The set rows.
  final List<LogSetRow> sets;

  /// This card with [sets].
  LogExerciseCard withSets(Iterable<LogSetRow> sets) =>
      LogExerciseCard(id: id, exerciseId: exerciseId, sets: sets);

  /// The domain view of this card.
  LogFormExercise toFormExercise() => LogFormExercise(
    id: id,
    exerciseId: exerciseId,
    sets: [for (final s in sets) s.toFormSet()],
  );
}

/// Where autosave stands (D8, PA3).
enum LogSaveState {
  /// Nothing pending, or saved.
  idle,

  /// A write is pending or in flight.
  saving,

  /// Another editor changed (or deleted) the session: autosave stopped
  /// until Reload or Keep mine.
  conflict,

  /// A save was refused for another reason; the next edit retries.
  failed,
}

/// The log form (WO-034, A37 D7-D9).
@immutable
final class LogFormState {
  /// A form for session [sessionId].
  new({
    required this.sessionId,
    required this.date,
    required this.today,
    required Iterable<LogExerciseCard> exercises,
    this.name = '',
    this.templateId,
    this.startTime,
    this.durationMinutes,
    this.persisted = false,
    this.saveState = LogSaveState.idle,
  }) : exercises = List.unmodifiable(exercises);

  /// The session row's ID (new or existing).
  final String sessionId;

  /// The training day.
  final LocalDate date;

  /// Today, for the date picker's limit (WO-011).
  final LocalDate today;

  /// The name as typed; empty = the auto name (D10).
  final String name;

  /// The template it came from (kept by Repeat), or `null`.
  final String? templateId;

  /// Kept from the stored session (the form doesn't edit them).
  final LocalTime? startTime;

  /// Kept from the stored session.
  final int? durationMinutes;

  /// The exercise cards in order.
  final List<LogExerciseCard> exercises;

  /// Whether a session row exists (it's written at the first ✓).
  final bool persisted;

  /// Autosave's state.
  final LogSaveState saveState;

  /// Whether any set is checked.
  bool get hasChecked => exercises.any((e) => e.sets.any((s) => s.checked));

  /// The session autosave writes now, or `null` with no checked set (D8).
  WorkoutSessionDraft? get savedDraft => LogFormDraft.savedDraftOf(
    [for (final e in exercises) e.toFormExercise()],
    date: date,
    name: name,
    templateId: templateId,
    startTime: startTime,
    durationMinutes: durationMinutes,
  );

  /// This state with some fields changed.
  LogFormState copyWith({
    LocalDate? date,
    String? name,
    Iterable<LogExerciseCard>? exercises,
    bool? persisted,
    LogSaveState? saveState,
  }) => LogFormState(
    sessionId: sessionId,
    date: date ?? this.date,
    today: today,
    name: name ?? this.name,
    templateId: templateId,
    startTime: startTime,
    durationMinutes: durationMinutes,
    exercises: exercises ?? this.exercises,
    persisted: persisted ?? this.persisted,
    saveState: saveState ?? this.saveState,
  );
}

/// What leaving the form did (D8, D9): the screen shows the snackbar.
@immutable
sealed class VisitResult {
  const new _();
}

/// Nothing was written in this visit.
final class VisitUnchanged extends VisitResult {
  /// Nothing written.
  const new() : super._();
}

/// "Update the Push template with these changes?" (WO-022, A37 D21): the
/// session's template and what it would become. Nothing is written until
/// the user taps Update.
@immutable
final class TemplateUpdateOffer {
  /// An offer to give [template] the content [draft].
  const new({required this.template, required this.draft});

  /// The live template the session was started from.
  final Stored<WorkoutTemplateDraft> template;

  /// The template with the session's lines (same name).
  final WorkoutTemplateDraft draft;
}

/// The visit saved a new session ([created]) or updated one. [undoId] is
/// its one Undo, or `null` after a conflict dropped it (PA3) or while an
/// [offer] is pending: the screen asks first, then records the Undo
/// (`WorkoutLogController.recordVisitUndo`), so the question never uses up
/// the undo window.
final class VisitSaved extends VisitResult {
  /// Saved; undo with [undoId].
  const new({required this.created, required this.undoId, this.offer})
    : super._();

  /// Whether the session is new.
  final bool created;

  /// The undo entry, or `null`.
  final String? undoId;

  /// The template-update offer (WO-022), or `null` when the session has no
  /// template or matches it.
  final TemplateUpdateOffer? offer;
}

/// The visit ended with no checked set, so the session was deleted (D8);
/// [undoId] restores it as last saved.
final class VisitDeleted extends VisitResult {
  /// Deleted; undo with [undoId].
  const new(this.undoId) : super._();

  /// The undo entry.
  final String undoId;
}

/// Leaving found a conflict (PA3): the visit stays open with Reload / Keep
/// mine, nothing was lost, and this visit has no Undo.
final class VisitConflict extends VisitResult {
  /// A conflict.
  const new() : super._();
}

/// Leaving couldn't write the newest form (storage failed or the write was
/// refused): the visit stays open with Retry / Leave without saving.
final class VisitFailed extends VisitResult {
  /// A failed write.
  const new() : super._();
}
