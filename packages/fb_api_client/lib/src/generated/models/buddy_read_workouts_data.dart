// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_exercise_pr.dart';
import 'buddy_workout_session_row.dart';

part 'buddy_read_workouts_data.freezed.dart';
part 'buddy_read_workouts_data.g.dart';

@Freezed()
abstract class BuddyReadWorkoutsData with _$BuddyReadWorkoutsData {
  const factory BuddyReadWorkoutsData({
    required List<BuddyWorkoutSessionRow> sessions,
    required List<BuddyExercisePr> prs,
  }) = _BuddyReadWorkoutsData;

  factory BuddyReadWorkoutsData.fromJson(Map<String, Object?> json) =>
      _$BuddyReadWorkoutsDataFromJson(json);
}
