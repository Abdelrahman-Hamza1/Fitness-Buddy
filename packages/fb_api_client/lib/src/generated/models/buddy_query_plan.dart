// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_query_filters.dart';
import 'buddy_query_metric.dart';
import 'buddy_query_op.dart';
import 'buddy_query_period.dart';

part 'buddy_query_plan.freezed.dart';
part 'buddy_query_plan.g.dart';

/// The frozen QueryPlan grammar (06 §6.3). Valid combinations (anything else is ok:false unsupportedPlan): remaining only with period today and kcal/protein/carbs/fat/fiber; total, average, max, min with kcal/protein/carbs/fat/fiber, sets, volume; latest, change with weight, weightTrend, measurement, exercisePr; count with workouts, sets, weighIns, loggedDays; last only with exerciseLastDate, filtered by exerciseRef or muscleGroup. Every period is at most 400 days.
@Freezed()
abstract class BuddyQueryPlan with _$BuddyQueryPlan {
  const factory BuddyQueryPlan({
    required BuddyQueryMetric metric,

    /// With metric measurement: a built-in kind (waist, chest, hips, arm, thigh, neck, bodyFat) or a custom type UUID; otherwise null.
    required String? measurementType,
    required BuddyQueryOp op,
    required BuddyQueryPeriod period,
    required BuddyQueryFilters? filters,
  }) = _BuddyQueryPlan;

  factory BuddyQueryPlan.fromJson(Map<String, Object?> json) =>
      _$BuddyQueryPlanFromJson(json);
}
