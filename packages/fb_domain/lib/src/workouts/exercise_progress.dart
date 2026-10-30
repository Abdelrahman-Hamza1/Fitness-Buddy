import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/workouts/exercise_type.dart';
import 'package:fb_domain/src/workouts/personal_records.dart';
import 'package:fb_domain/src/workouts/workout_history.dart';
import 'package:fb_domain/src/workouts/workout_set.dart';

/// What an exercise page's graph plots per session (WO-041, A37 D11).
enum ExerciseMetric {
  /// The heaviest set's weight, in kg (weight × reps: the main line).
  heaviest,

  /// The best estimated one-rep max by Epley, in kg (weight × reps: the
  /// toggle).
  e1rm,

  /// The most reps in one set (bodyweight, reps only, assisted).
  mostReps,

  /// The longest set, in seconds (time, cardio).
  longest,
}

/// One session of an exercise: when, and its sets (all its entries in that
/// session, in order).
typedef ExerciseSession = ({
  String sessionId,
  LocalDate date,
  List<SetValues> sets,
});

/// One point of an exercise's graph: a session and its value in the
/// metric's unit.
typedef ExercisePoint = ({String sessionId, LocalDate date, double value});

/// One exercise's progress over a history (WO-041, IN-006): its sessions,
/// the per-session series and its bests. Derived on read, never stored.
final class ExerciseProgress {
  new _(this.type, this.sessions);

  /// The progress of [exerciseId], an exercise of [type], over [history]
  /// (any order).
  factory of(
    Iterable<SessionEntry> history,
    String exerciseId,
    ExerciseType type,
  ) {
    final ordered = history.toList()..sort(compareSessions);
    return ExerciseProgress._(type, [
      for (final session in ordered)
        if ([
              for (final e in session.draft.exercises)
                if (e.exerciseId == exerciseId)
                  for (final set in e.sets) set.values,
            ]
            case final sets when sets.isNotEmpty)
          (
            sessionId: session.id,
            date: session.draft.date,
            sets: List<SetValues>.unmodifiable(sets),
          ),
    ]);
  }

  /// What a set logs.
  final ExerciseType type;

  /// The sessions with this exercise, oldest first.
  final List<ExerciseSession> sessions;

  /// The graph's main line: heaviest set for weight × reps (D-085), most
  /// reps for bodyweight, reps-only and assisted, longest for time and
  /// cardio.
  ExerciseMetric get main => switch (type) {
    ExerciseType.weightReps => ExerciseMetric.heaviest,
    ExerciseType.bodyweightReps ||
    ExerciseType.repsOnly ||
    ExerciseType.assisted => ExerciseMetric.mostReps,
    ExerciseType.duration ||
    ExerciseType.distanceDuration => ExerciseMetric.longest,
  };

  /// Whether the estimated 1RM toggle applies (weight × reps only).
  bool get hasE1rm => type == ExerciseType.weightReps;

  /// One point per session that has a value for [metric], oldest first.
  List<ExercisePoint> series(ExerciseMetric metric) => List.unmodifiable([
    for (final s in sessions)
      if (_best(metric, s.sets) case final value?)
        (sessionId: s.sessionId, date: s.date, value: value),
  ]);

  /// The records over every session (WO-042): weight × reps all three,
  /// bodyweight and reps-only most reps (at the added load); none for the
  /// other types.
  PersonalRecords get records => PersonalRecords.of([
    for (final s in sessions)
      for (final set in s.sets) ?liftedSetOf(type, set),
  ]);

  /// The best of [metric] over every session, or `null` without one.
  double? best(ExerciseMetric metric) =>
      _best(metric, [for (final s in sessions) ...s.sets]);

  /// The longest distance of one set in metres (cardio), or `null`.
  double? get farthestMeters {
    double? best;
    for (final s in sessions) {
      for (final set in s.sets) {
        final m = set.distanceMeters;
        if (m != null && m.isFinite && m > 0 && (best == null || m > best)) {
          best = m;
        }
      }
    }
    return best;
  }

  double? _best(ExerciseMetric metric, List<SetValues> sets) {
    double? best;
    for (final set in sets) {
      final value = _valueOf(metric, set);
      if (value != null && (best == null || value > best)) best = value;
    }
    return best;
  }

  double? _valueOf(ExerciseMetric metric, SetValues set) {
    final reps = set.reps;
    final kg = set.kg;
    final seconds = set.durationSeconds;
    // Weight and e1RM mean something only for weight × reps (an assisted
    // set's kg is help, not load).
    final lifted =
        type == ExerciseType.weightReps &&
        reps != null &&
        reps >= 1 &&
        kg != null &&
        kg.isFinite;
    return switch (metric) {
      ExerciseMetric.heaviest when lifted && kg > 0 => kg,
      ExerciseMetric.e1rm when lifted && kg > 0 => epleyE1rm(kg, reps),
      ExerciseMetric.mostReps when reps != null && reps >= 1 => reps.toDouble(),
      ExerciseMetric.longest when seconds != null && seconds > 0 =>
        seconds.toDouble(),
      _ => null,
    };
  }
}
