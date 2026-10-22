// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_range.dart';

part 'buddy_estimate.freezed.dart';
part 'buddy_estimate.g.dart';

@Freezed()
abstract class BuddyEstimate with _$BuddyEstimate {
  const factory BuddyEstimate({
    /// AI-estimated nutrient range per 100 grams; never overrides a real food match.
    required BuddyRange range,
    required String reason,
  }) = _BuddyEstimate;

  factory BuddyEstimate.fromJson(Map<String, Object?> json) =>
      _$BuddyEstimateFromJson(json);
}
