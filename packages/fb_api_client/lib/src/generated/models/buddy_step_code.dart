// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum BuddyStepCode {
  @JsonValue('searchingFoods')
  searchingFoods('searchingFoods'),
  @JsonValue('readingDiary')
  readingDiary('readingDiary'),
  @JsonValue('readingYourFoods')
  readingYourFoods('readingYourFoods'),
  @JsonValue('readingBody')
  readingBody('readingBody'),
  @JsonValue('readingWorkouts')
  readingWorkouts('readingWorkouts'),
  @JsonValue('readingMemory')
  readingMemory('readingMemory'),
  @JsonValue('computing')
  computing('computing'),
  @JsonValue('checkingFit')
  checkingFit('checkingFit'),
  @JsonValue('writingReply')
  writingReply('writingReply'),
  @JsonValue('summarizing')
  summarizing('summarizing'),
  @JsonValue('searchingExercises')
  searchingExercises('searchingExercises'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BuddyStepCode(this.json);

  factory BuddyStepCode.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BuddyStepCode> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
