// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_amount.dart';
import 'buddy_day_hint.dart';
import 'buddy_food_item.dart';

part 'buddy_diary_patch.freezed.dart';
part 'buddy_diary_patch.g.dart';

/// At least one member is non-null. amount is the new absolute amount (relative edits are clarified as unsupported); it is null when replacement is set. replacement swaps the food, including a state or variant change; its amount with explicit false and a null value keeps the entry's amount. move: a null member keeps the entry's day, slot or time; a move with all three null is invalid.
@Freezed()
abstract class BuddyDiaryPatch with _$BuddyDiaryPatch {
  const factory BuddyDiaryPatch({
    required BuddyAmount? amount,
    required BuddyFoodItem? replacement,
    required BuddyDayHint? move,
  }) = _BuddyDiaryPatch;

  factory BuddyDiaryPatch.fromJson(Map<String, Object?> json) =>
      _$BuddyDiaryPatchFromJson(json);
}
