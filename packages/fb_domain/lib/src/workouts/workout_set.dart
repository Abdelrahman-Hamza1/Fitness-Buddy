import 'package:fb_domain/src/workouts/exercise_type.dart';

/// The limits of a logged set (A36 D2). They apply to local writes only:
/// rows read from sync are never rejected.
abstract final class WorkoutSetBounds {
  /// Fewest reps in a set.
  static const int minReps = 1;

  /// Most reps in a set.
  static const int maxReps = 1000;

  /// Most sets one notation may produce.
  static const int maxSets = 20;

  /// Heaviest load (weight, added or assistance), in kg.
  static const double maxKg = 1000;

  /// Longest set duration: 24 hours, in seconds.
  static const int maxDurationSeconds = 86400;

  /// Longest distance: 1,000 km, in metres.
  static const double maxDistanceMeters = 1000000;
}

/// Why a set's values don't fit its exercise type (WO-004). Content-free:
/// the app maps each to an ARB string.
enum WorkoutSetIssue {
  /// The type needs reps and there are none, or they're out of range.
  reps,

  /// The type logs no reps but the set has some.
  unexpectedReps,

  /// The weight is missing (weight × reps, assistance) or out of range.
  weight,

  /// The set has a weight field its type doesn't log.
  unexpectedWeight,

  /// The type needs a duration and there's none, or it's out of range.
  duration,

  /// The type logs no duration but the set has one.
  unexpectedDuration,

  /// The distance is out of range, or the type logs none.
  distance,
}

/// One logged set's values, canonical units: kg, seconds, metres (WO-004).
///
/// Which fields are set depends on the type: weight × reps uses [kg] and
/// [reps]; bodyweight uses [reps] and optional [kg] as added load; assisted
/// uses [reps] and [kg] (required) as assistance; reps only uses [reps];
/// time uses [durationSeconds]; cardio uses [durationSeconds] and optional
/// [distanceMeters]. A dumbbell exercise's [kg] is per dumbbell (WO-005).
final class SetValues {
  /// The values as given; see [issueFor].
  const new({this.reps, this.kg, this.durationSeconds, this.distanceMeters});

  /// Repetitions.
  final int? reps;

  /// The load in kg: the weight, the added load or the assistance, by type.
  final double? kg;

  /// The duration in seconds.
  final int? durationSeconds;

  /// The distance in metres.
  final double? distanceMeters;

  /// The first reason these values don't fit [type], or `null` if they do.
  WorkoutSetIssue? issueFor(ExerciseType type) {
    final reps = this.reps;
    final kg = this.kg;
    final duration = durationSeconds;
    final distance = distanceMeters;
    if (type.hasReps) {
      if (reps == null ||
          reps < WorkoutSetBounds.minReps ||
          reps > WorkoutSetBounds.maxReps) {
        return WorkoutSetIssue.reps;
      }
      if (duration != null) return WorkoutSetIssue.unexpectedDuration;
      if (distance != null) return WorkoutSetIssue.distance;
    } else {
      if (reps != null) return WorkoutSetIssue.unexpectedReps;
      if (kg != null) return WorkoutSetIssue.unexpectedWeight;
      if (duration == null ||
          duration < 1 ||
          duration > WorkoutSetBounds.maxDurationSeconds) {
        return WorkoutSetIssue.duration;
      }
      if (distance != null &&
          (type != ExerciseType.distanceDuration ||
              !distance.isFinite ||
              distance <= 0 ||
              distance > WorkoutSetBounds.maxDistanceMeters)) {
        return WorkoutSetIssue.distance;
      }
      return null;
    }
    return switch (type) {
      ExerciseType.weightReps when kg == null || !_loadOk(kg, positive: true) =>
        WorkoutSetIssue.weight,
      // Assisted sets need the assistance weight (WO-004).
      ExerciseType.assisted when kg == null || !_loadOk(kg, positive: true) =>
        WorkoutSetIssue.weight,
      ExerciseType.bodyweightReps
          when kg != null && !_loadOk(kg, positive: false) =>
        WorkoutSetIssue.weight,
      ExerciseType.repsOnly when kg != null => WorkoutSetIssue.unexpectedWeight,
      _ => null,
    };
  }

  static bool _loadOk(double kg, {required bool positive}) =>
      kg.isFinite &&
      (positive ? kg > 0 : kg >= 0) &&
      kg <= WorkoutSetBounds.maxKg;

  @override
  bool operator ==(Object other) =>
      other is SetValues &&
      other.reps == reps &&
      other.kg == kg &&
      other.durationSeconds == durationSeconds &&
      other.distanceMeters == distanceMeters;

  @override
  int get hashCode => Object.hash(reps, kg, durationSeconds, distanceMeters);

  @override
  String toString() =>
      'SetValues(reps: $reps, kg: $kg, s: $durationSeconds, '
      'm: $distanceMeters)';
}
