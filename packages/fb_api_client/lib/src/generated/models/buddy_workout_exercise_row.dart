// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_set_row.dart';

part 'buddy_workout_exercise_row.freezed.dart';
part 'buddy_workout_exercise_row.g.dart';

@Freezed()
abstract class BuddyWorkoutExerciseRow with _$BuddyWorkoutExerciseRow {
  const factory BuddyWorkoutExerciseRow({
    required String name,
    required String exerciseRef,
    required List<BuddySetRow> sets,
  }) = _BuddyWorkoutExerciseRow;

  factory BuddyWorkoutExerciseRow.fromJson(Map<String, Object?> json) =>
      _$BuddyWorkoutExerciseRowFromJson(json);
}
