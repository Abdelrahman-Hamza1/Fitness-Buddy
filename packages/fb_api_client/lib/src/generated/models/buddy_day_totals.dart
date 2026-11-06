// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_day_targets.dart';

part 'buddy_day_totals.freezed.dart';
part 'buddy_day_totals.g.dart';

/// Today's eaten totals, with targets when set.
@Freezed()
abstract class BuddyDayTotals with _$BuddyDayTotals {
  const factory BuddyDayTotals({
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required double fiberG,
    required BuddyDayTargets? targets,
  }) = _BuddyDayTotals;

  factory BuddyDayTotals.fromJson(Map<String, Object?> json) =>
      _$BuddyDayTotalsFromJson(json);
}
