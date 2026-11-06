// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_claim_value.dart';
import 'buddy_coverage.dart';
import 'buddy_query_link.dart';

part 'buddy_query_result_data.freezed.dart';
part 'buddy_query_result_data.g.dart';

/// QueryEngine output: computed claims, how many days the period covered and how many were logged, and an optional screen link.
@Freezed()
abstract class BuddyQueryResultData with _$BuddyQueryResultData {
  const factory BuddyQueryResultData({
    required List<BuddyClaimValue> claims,
    required BuddyCoverage coverage,
    required BuddyQueryLink? link,
  }) = _BuddyQueryResultData;

  factory BuddyQueryResultData.fromJson(Map<String, Object?> json) =>
      _$BuddyQueryResultDataFromJson(json);
}
