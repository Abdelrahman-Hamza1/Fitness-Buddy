// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_call.dart';
import 'buddy_read_workouts_args.dart';
import 'buddy_read_workouts_call_name.dart';

part 'buddy_read_workouts_call.freezed.dart';
part 'buddy_read_workouts_call.g.dart';

/// Workout sessions over at most 90 days, at most 15 sessions, with PRs.
@Freezed()
abstract class BuddyReadWorkoutsCall with _$BuddyReadWorkoutsCall {
  const factory BuddyReadWorkoutsCall({
    required BuddyReadWorkoutsCallName name,
    required String callId,
    required BuddyReadWorkoutsArgs args,
  }) = _BuddyReadWorkoutsCall;

  factory BuddyReadWorkoutsCall.fromJson(Map<String, Object?> json) =>
      _$BuddyReadWorkoutsCallFromJson(json);
}
