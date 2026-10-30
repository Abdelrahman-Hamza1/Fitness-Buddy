import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/workouts/application/exercise_library.dart';
import 'package:fb_mobile/features/workouts/application/set_input.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';

/// Workout names and numbers as text (A37 §3.6): every word comes from the
/// ARB file.
extension WorkoutText on AppLocalizations {
  /// A muscle's name.
  String muscle(Muscle muscle) => workoutMuscle(muscle.name);

  /// A muscle group's name.
  String muscleGroup(MuscleGroup group) => workoutMuscleGroup(group.name);

  /// What an exercise type logs.
  String exerciseType(ExerciseType type) => workoutExerciseType(type.name);

  /// An equipment's name.
  String equipment(Equipment equipment) => workoutEquipment(equipment.name);

  /// A session's title (D10).
  String sessionTitle(SessionTitle title) => switch (title) {
    NamedTitle(:final name) => name,
    MuscleGroupsTitle(groups: [final only]) => muscleGroup(only),
    MuscleGroupsTitle(:final groups) => workoutTitlePair(
      groups.first.name,
      groups.last.name,
    ),
    FullBodyTitle() => workoutTitleFullBody,
    CardioTitle() => workoutTitleCardio,
    UntitledTitle() => workoutTitleUntitled,
  };

  /// Exercise [id]'s name in [library], or "Removed exercise" (D15).
  String exerciseName(ExerciseLibrary library, String id) =>
      library.byId[id]?.name ?? workoutRemovedExercise;

  /// One set's values for an exercise of [type], like "80 × 8" (D7).
  String setValues(ExerciseType? type, SetValues values) {
    final reps = values.reps;
    final kg = values.kg;
    final seconds = values.durationSeconds;
    return switch (type) {
      ExerciseType.weightReps when kg != null && reps != null =>
        workoutSetWeightReps(formatNumber(kg), reps),
      ExerciseType.bodyweightReps when reps != null =>
        kg != null && kg > 0
            ? workoutSetAddedWeight(formatNumber(kg), reps)
            : workoutSetReps(reps),
      ExerciseType.assisted when kg != null && reps != null =>
        workoutSetAssisted(formatNumber(kg), reps),
      ExerciseType.repsOnly when reps != null => workoutSetReps(reps),
      ExerciseType.duration when seconds != null => formatClock(seconds),
      ExerciseType.distanceDuration when seconds != null =>
        switch (values.distanceMeters) {
          final m? => workoutSetCardioDistance(
            formatNumber(seconds / 60),
            formatNumber(m / 1000),
          ),
          null => workoutSetCardio(formatNumber(seconds / 60)),
        },
      _ => '',
    };
  }
}
