// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_weight_trend.freezed.dart';
part 'buddy_weight_trend.g.dart';

@Freezed()
abstract class BuddyWeightTrend with _$BuddyWeightTrend {
  const factory BuddyWeightTrend({
    required String from,
    required String to,
    required double startKg,
    required double endKg,
    required double changeKg,
    required double? weeklyChangeKg,
    required int weighIns,
  }) = _BuddyWeightTrend;

  factory BuddyWeightTrend.fromJson(Map<String, Object?> json) =>
      _$BuddyWeightTrendFromJson(json);
}
