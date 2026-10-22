// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_nutrients.dart';
import 'buddy_range.dart';
import 'buddy_serving.dart';

part 'buddy_candidate.freezed.dart';
part 'buddy_candidate.g.dart';

@Freezed()
abstract class BuddyCandidate with _$BuddyCandidate {
  const factory BuddyCandidate({
    required String key,
    required String nameEn,
    required String? nameAr,
    required String state,
    required String source,
    required BuddyNutrients nutrients,
    required BuddyRange? ranges,
    required List<BuddyServing> servings,
    required double? densityGPerMl,
    required String? yieldGroup,
  }) = _BuddyCandidate;

  factory BuddyCandidate.fromJson(Map<String, Object?> json) =>
      _$BuddyCandidateFromJson(json);
}
