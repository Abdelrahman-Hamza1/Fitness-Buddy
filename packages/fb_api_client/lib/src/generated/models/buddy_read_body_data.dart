// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_body_value.dart';
import 'buddy_weight_trend.dart';

part 'buddy_read_body_data.freezed.dart';
part 'buddy_read_body_data.g.dart';

@Freezed()
abstract class BuddyReadBodyData with _$BuddyReadBodyData {
  const factory BuddyReadBodyData({
    /// Canonical units: kg for weight, cm or percent for measurements.
    required List<BuddyBodyValue> values,
    required BuddyWeightTrend? trend,
  }) = _BuddyReadBodyData;

  factory BuddyReadBodyData.fromJson(Map<String, Object?> json) =>
      _$BuddyReadBodyDataFromJson(json);
}
