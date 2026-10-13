// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_item.freezed.dart';
part 'food_item.g.dart';

@Freezed()
abstract class FoodItem with _$FoodItem {
  const factory FoodItem({
    required String query,
    required double quantity,
    required String unit,
  }) = _FoodItem;

  factory FoodItem.fromJson(Map<String, Object?> json) =>
      _$FoodItemFromJson(json);
}
