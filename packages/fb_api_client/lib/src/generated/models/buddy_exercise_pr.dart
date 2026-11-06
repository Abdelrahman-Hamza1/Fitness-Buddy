// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_exercise_pr.freezed.dart';
part 'buddy_exercise_pr.g.dart';

@Freezed()
abstract class BuddyExercisePr with _$BuddyExercisePr {
  const factory BuddyExercisePr({
    required String name,
    required String exerciseRef,
    required double? kg,
    required int? reps,
    required String date,
  }) = _BuddyExercisePr;

  factory BuddyExercisePr.fromJson(Map<String, Object?> json) =>
      _$BuddyExercisePrFromJson(json);
}
