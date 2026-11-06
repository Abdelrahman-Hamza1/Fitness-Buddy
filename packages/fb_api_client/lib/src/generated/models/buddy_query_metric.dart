// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum BuddyQueryMetric {
  @JsonValue('kcal')
  kcal('kcal'),
  @JsonValue('protein')
  protein('protein'),
  @JsonValue('carbs')
  carbs('carbs'),
  @JsonValue('fat')
  fat('fat'),
  @JsonValue('fiber')
  fiber('fiber'),
  @JsonValue('weight')
  weight('weight'),
  @JsonValue('weightTrend')
  weightTrend('weightTrend'),
  @JsonValue('measurement')
  measurement('measurement'),
  @JsonValue('workouts')
  workouts('workouts'),
  @JsonValue('sets')
  sets('sets'),
  @JsonValue('volume')
  volume('volume'),
  @JsonValue('exerciseLastDate')
  exerciseLastDate('exerciseLastDate'),
  @JsonValue('exercisePr')
  exercisePr('exercisePr'),
  @JsonValue('weighIns')
  weighIns('weighIns'),
  @JsonValue('loggedDays')
  loggedDays('loggedDays'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BuddyQueryMetric(this.json);

  factory BuddyQueryMetric.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BuddyQueryMetric> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
