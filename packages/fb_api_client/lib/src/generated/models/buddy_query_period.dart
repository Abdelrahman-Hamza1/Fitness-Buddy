// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_period_kind.dart';
import 'buddy_since_event.dart';

part 'buddy_query_period.freezed.dart';
part 'buddy_query_period.g.dart';

/// today | yesterday | thisWeek | lastWeek | thisMonth | lastMonth; lastNDays with days 1–400; since with since ramadanStart | phaseStart | date (then from is the date); range with from and to (inclusive, ≤ 400 days). Members a kind doesn't use are null.
@Freezed()
abstract class BuddyQueryPeriod with _$BuddyQueryPeriod {
  const factory BuddyQueryPeriod({
    required BuddyPeriodKind kind,
    required int? days,
    required BuddySinceEvent? since,
    required String? from,
    required String? to,
  }) = _BuddyQueryPeriod;

  factory BuddyQueryPeriod.fromJson(Map<String, Object?> json) =>
      _$BuddyQueryPeriodFromJson(json);
}
