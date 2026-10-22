// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_amount.dart';
import 'buddy_candidate.dart';
import 'buddy_dimension.dart';
import 'buddy_estimate.dart';
import 'buddy_share.dart';

part 'buddy_food_item.freezed.dart';
part 'buddy_food_item.g.dart';

@Freezed()
abstract class BuddyFoodItem with _$BuddyFoodItem {
  const factory BuddyFoodItem({
    required String mention,
    required BuddyCandidate? match,
    required List<BuddyCandidate> alternatives,
    required BuddyAmount amount,
    required BuddyShare? share,
    required List<BuddyDimension> dimensions,
    required BuddyEstimate? estimate,
  }) = _BuddyFoodItem;

  factory BuddyFoodItem.fromJson(Map<String, Object?> json) =>
      _$BuddyFoodItemFromJson(json);
}
