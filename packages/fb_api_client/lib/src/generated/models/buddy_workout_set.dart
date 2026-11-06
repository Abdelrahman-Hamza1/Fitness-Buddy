// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_load_unit.dart';

part 'buddy_workout_set.freezed.dart';
part 'buddy_workout_set.g.dart';

@Freezed()
abstract class BuddyWorkoutSet with _$BuddyWorkoutSet {
  const factory BuddyWorkoutSet({
    required int? reps,
    required double? weight,
    required BuddyLoadUnit? unit,

    /// The stated weight is per dumbbell.
    required bool perDumbbell,
    required int? durationSeconds,
    required double? distanceMeters,
  }) = _BuddyWorkoutSet;

  factory BuddyWorkoutSet.fromJson(Map<String, Object?> json) =>
      _$BuddyWorkoutSetFromJson(json);
}
