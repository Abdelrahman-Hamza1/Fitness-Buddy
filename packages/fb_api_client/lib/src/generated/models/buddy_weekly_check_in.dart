// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_weekly_check_in.freezed.dart';
part 'buddy_weekly_check_in.g.dart';

/// Base calorie target now and as proposed (kcal/day).
@Freezed()
abstract class BuddyWeeklyCheckIn with _$BuddyWeeklyCheckIn {
  const factory BuddyWeeklyCheckIn({
    required double currentKcal,
    required double proposedKcal,
  }) = _BuddyWeeklyCheckIn;

  factory BuddyWeeklyCheckIn.fromJson(Map<String, Object?> json) =>
      _$BuddyWeeklyCheckInFromJson(json);
}
