// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_intent.dart';
import 'buddy_workout_exercise.dart';
import 'buddy_workout_kind.dart';

part 'buddy_workout.freezed.dart';
part 'buddy_workout.g.dart';

/// A workout session to log (B26, WO-030–033).
@Freezed()
abstract class BuddyWorkout with _$BuddyWorkout {
  const factory BuddyWorkout({
    required BuddyWorkoutKind kind,
    required String? name,
    required String language,
    required String script,
    required String? timeHint,
    required String? dateHint,
    required List<BuddyWorkoutExercise> exercises,
  }) = _BuddyWorkout;

  factory BuddyWorkout.fromJson(Map<String, Object?> json) =>
      _$BuddyWorkoutFromJson(json);
}
