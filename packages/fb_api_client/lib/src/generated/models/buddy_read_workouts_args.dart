// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_date_range.dart';

part 'buddy_read_workouts_args.freezed.dart';
part 'buddy_read_workouts_args.g.dart';

@Freezed()
abstract class BuddyReadWorkoutsArgs with _$BuddyReadWorkoutsArgs {
  const factory BuddyReadWorkoutsArgs({
    required BuddyDateRange range,
    required String? exerciseRef,
  }) = _BuddyReadWorkoutsArgs;

  factory BuddyReadWorkoutsArgs.fromJson(Map<String, Object?> json) =>
      _$BuddyReadWorkoutsArgsFromJson(json);
}
