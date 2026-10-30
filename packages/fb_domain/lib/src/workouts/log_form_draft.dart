import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';
import 'package:fb_domain/src/workouts/workout_drafts.dart';

/// One set row of the log form (WO-034, A37 D8): its stable row ID, whether
/// it's checked (done), and its last valid values. An edit that makes the
/// inputs invalid keeps [value] at the last valid one, so autosave keeps the
/// saved number.
final class LogFormSet {
  /// Set row [id]; [value] is `null` until the row has valid values, and
  /// has the same ID (else an `ArgumentError`).
  new({required this.id, required this.checked, this.value}) {
    if (value case final v? when v.id != id) {
      throw ArgumentError.value(v.id, 'value', 'must have the row ID');
    }
  }

  /// The set row's ID, stable for the whole form visit.
  final String id;

  /// Whether the set is done (only checked sets are saved).
  final bool checked;

  /// The last valid values, with this row's [id].
  final LoggedSet? value;
}

/// One exercise card of the log form, in form order.
final class LogFormExercise {
  /// Session-exercise row [id] of [exerciseId] with [sets].
  new({
    required this.id,
    required this.exerciseId,
    required Iterable<LogFormSet> sets,
  }) : sets = List.unmodifiable(sets);

  /// The session-exercise row's ID, stable for the whole form visit.
  final String id;

  /// A catalog ID or a custom exercise's UUID.
  final String exerciseId;

  /// The set rows, in order.
  final List<LogFormSet> sets;
}

/// What "saves as you type" writes (WO-034, A37 D8, PA2): a pure function of
/// the form, so every transition (check, uncheck, delete, re-check, an
/// exercise losing its last checked set) is defined by what it leaves here.
abstract final class LogFormDraft {
  /// The saved exercises: in form order, those with at least one checked
  /// set with values, each with only those sets, keeping the form's row IDs.
  static List<SessionExerciseDraft> exercisesOf(
    Iterable<LogFormExercise> exercises,
  ) => [
    for (final exercise in exercises)
      if ([
            for (final set in exercise.sets)
              if (set.checked) ?set.value,
          ]
          case final sets when sets.isNotEmpty)
        SessionExerciseDraft(
          id: exercise.id,
          exerciseId: exercise.exerciseId,
          sets: sets,
        ),
  ];

  /// The session the form saves, or `null` when it has no checked set
  /// (autosave never writes an empty session). The form edits neither
  /// [startTime] nor [durationMinutes]; they pass through from the stored
  /// session.
  static WorkoutSessionDraft? savedDraftOf(
    Iterable<LogFormExercise> exercises, {
    required LocalDate date,
    String? name,
    String? templateId,
    LocalTime? startTime,
    int? durationMinutes,
  }) {
    final saved = exercisesOf(exercises);
    if (saved.isEmpty) return null;
    return WorkoutSessionDraft(
      date: date,
      name: name == null || name.trim().isEmpty ? null : name,
      templateId: templateId,
      startTime: startTime,
      durationMinutes: durationMinutes,
      exercises: saved,
    );
  }
}
