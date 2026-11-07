// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_weekly_check_in.dart';
import 'buddy_weekly_workouts.dart';

part 'buddy_weekly_summary.freezed.dart';
part 'buddy_weekly_summary.g.dart';

/// The week's aggregates for mode weeklyReview (B26, AI-130; the app's WeeklySummary): counted days only, no diary rows or names. Every number becomes a code-rendered fact.
@Freezed()
abstract class BuddyWeeklySummary with _$BuddyWeeklySummary {
  const factory BuddyWeeklySummary({
    required String start,
    required String end,

    /// Days of the week before today (7 for a past week).
    required int elapsedDays,

    /// Logged, complete days that enter averages (TG-032).
    required int countedDays,
    required int targetDays,

    /// Counted days within 10 % of the calorie target.
    required int daysWithinTarget,
    required int proteinTargetDays,
    required int proteinDaysHit,

    /// Average intake over the target days.
    required double? averageKcal,

    /// Average calorie target over the same days.
    required double? averageTargetKcal,
    required double? averageFiberG,

    /// Trend weight change over the week (kg).
    required double? trendChangeKg,
    required BuddyWeeklyWorkouts? workouts,

    /// Some counted days include estimates.
    required bool estimated,

    /// The phone's adaptive check-in proposal (A38), when it proposes a change; the app attaches its own pending targetChange card to the review.
    required BuddyWeeklyCheckIn? checkIn,
  }) = _BuddyWeeklySummary;

  factory BuddyWeeklySummary.fromJson(Map<String, Object?> json) =>
      _$BuddyWeeklySummaryFromJson(json);
}
