// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_error.dart';
import 'buddy_phone_tool_result.dart';
import 'buddy_read_workouts_data.dart';
import 'buddy_read_workouts_result_name.dart';

part 'buddy_read_workouts_result.freezed.dart';
part 'buddy_read_workouts_result.g.dart';

@Freezed()
abstract class BuddyReadWorkoutsResult with _$BuddyReadWorkoutsResult {
  const factory BuddyReadWorkoutsResult({
    required BuddyReadWorkoutsResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyReadWorkoutsData? data,
  }) = _BuddyReadWorkoutsResult;

  factory BuddyReadWorkoutsResult.fromJson(Map<String, Object?> json) =>
      _$BuddyReadWorkoutsResultFromJson(json);
}
