// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_day_targets.freezed.dart';
part 'buddy_day_targets.g.dart';

@Freezed()
abstract class BuddyDayTargets with _$BuddyDayTargets {
  const factory BuddyDayTargets({
    required double? kcal,
    required double? proteinG,
    required double? carbsG,
    required double? fatG,
    required double? fiberG,
  }) = _BuddyDayTargets;

  factory BuddyDayTargets.fromJson(Map<String, Object?> json) =>
      _$BuddyDayTargetsFromJson(json);
}
