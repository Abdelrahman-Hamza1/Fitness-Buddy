// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_workout_exercise_row.dart';

part 'buddy_workout_session_row.freezed.dart';
part 'buddy_workout_session_row.g.dart';

@Freezed()
abstract class BuddyWorkoutSessionRow with _$BuddyWorkoutSessionRow {
  const factory BuddyWorkoutSessionRow({
    required String? name,
    required String id,
    required String date,
    required List<BuddyWorkoutExerciseRow> exercises,
  }) = _BuddyWorkoutSessionRow;

  factory BuddyWorkoutSessionRow.fromJson(Map<String, Object?> json) =>
      _$BuddyWorkoutSessionRowFromJson(json);
}
