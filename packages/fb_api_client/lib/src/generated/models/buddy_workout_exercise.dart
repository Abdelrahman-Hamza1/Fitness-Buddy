// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_workout_set.dart';

part 'buddy_workout_exercise.freezed.dart';
part 'buddy_workout_exercise.g.dart';

@Freezed()
abstract class BuddyWorkoutExercise with _$BuddyWorkoutExercise {
  const factory BuddyWorkoutExercise({
    required String mention,

    /// A library exercise code or a custom exercise UUID; null when nothing matched (the app asks, WO-033).
    required String? exerciseRef,
    required List<BuddyWorkoutSet> sets,
    required List<String> assumptions,
  }) = _BuddyWorkoutExercise;

  factory BuddyWorkoutExercise.fromJson(Map<String, Object?> json) =>
      _$BuddyWorkoutExerciseFromJson(json);
}
