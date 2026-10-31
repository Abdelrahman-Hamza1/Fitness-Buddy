import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/workouts/exercise_type.dart';
import 'package:fb_domain/src/workouts/muscle.dart';
import 'package:fb_domain/src/workouts/personal_records.dart';
import 'package:fb_domain/src/workouts/workout_history.dart';
import 'package:fb_domain/src/workouts/workout_set.dart';

/// An exercise's muscles, as a map shows them.
typedef ExerciseMuscles = ({Muscle? primary, List<Muscle> secondaries});

/// The muscles of several exercises together (A52 D4): a session's or a
/// workout day's map. Every main muscle is primary; a secondary muscle is
/// secondary only when no exercise has it as its main muscle.
final class MuscleUnion {
  new _(this.primary, this.secondary);

  /// The union of [exercises]' muscles.
  factory of(Iterable<ExerciseMuscles> exercises) {
    final list = exercises.toList();
    final primary = <Muscle>{for (final e in list) ?e.primary}.toList();
    final secondary = <Muscle>{
      for (final e in list)
        for (final m in e.secondaries)
          if (!primary.contains(m)) m,
    }.toList();
    return MuscleUnion._(
      List.unmodifiable(primary),
      List.unmodifiable(secondary),
    );
  }

  /// The main muscles, distinct, in exercise order.
  final List<Muscle> primary;

  /// The other muscles worked, distinct, never in [primary].
  final List<Muscle> secondary;
}

/// One exercise the user did recently (A52 D3): when, and its top set.
typedef RecentExercise = ({String exerciseId, LocalDate date, SetValues top});

/// The exercises of the user's own sessions, most recent first (A52 D3):
/// the picker's "Your recent".
abstract final class RecentExercises {
  /// The distinct exercises of [sessions] (newest session first, history
  /// order; within a session, form order) with that session's top set, at
  /// most [limit]. Exercises without sets are skipped. [typeOf] types the
  /// top set (`null`: unknown, the first set).
  static List<RecentExercise> of(
    Iterable<SessionEntry> sessions,
    ExerciseType? Function(String exerciseId) typeOf, {
    int limit = 5,
  }) {
    final ordered = sessions.toList()..sort((a, b) => compareSessions(b, a));
    final seen = <String>{};
    final result = <RecentExercise>[];
    for (final session in ordered) {
      for (final exercise in session.draft.exercises) {
        if (result.length >= limit) return List.unmodifiable(result);
        if (exercise.sets.isEmpty || !seen.add(exercise.exerciseId)) continue;
        result.add((
          exerciseId: exercise.exerciseId,
          date: session.draft.date,
          top: topSetOf(typeOf(exercise.exerciseId), [
            for (final s in exercise.sets) s.values,
          ]),
        ));
      }
    }
    return List.unmodifiable(result);
  }

  /// The top set of non-empty [sets] of an exercise of [type]: the heaviest
  /// weight, then the most reps, for types that keep records; otherwise
  /// (time, cardio, assisted, unknown) the first set.
  static SetValues topSetOf(ExerciseType? type, List<SetValues> sets) {
    if (type == null) return sets.first;
    SetValues? best;
    LiftedSet? bestLift;
    for (final set in sets) {
      final lift = liftedSetOf(type, set);
      if (lift == null) continue;
      if (bestLift == null ||
          lift.kg > bestLift.kg ||
          (lift.kg == bestLift.kg && lift.reps > bestLift.reps)) {
        best = set;
        bestLift = lift;
      }
    }
    return best ?? sets.first;
  }
}
