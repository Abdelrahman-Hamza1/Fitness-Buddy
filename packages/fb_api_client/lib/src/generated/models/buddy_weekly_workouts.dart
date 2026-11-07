// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_weekly_workouts.freezed.dart';
part 'buddy_weekly_workouts.g.dart';

/// Sessions logged, planned training days (null without a plan; never a missed count, WO-024) and exercises that set a PR.
@Freezed()
abstract class BuddyWeeklyWorkouts with _$BuddyWeeklyWorkouts {
  const factory BuddyWeeklyWorkouts({
    required int sessions,
    required int? planned,
    required int prs,
  }) = _BuddyWeeklyWorkouts;

  factory BuddyWeeklyWorkouts.fromJson(Map<String, Object?> json) =>
      _$BuddyWeeklyWorkoutsFromJson(json);
}
