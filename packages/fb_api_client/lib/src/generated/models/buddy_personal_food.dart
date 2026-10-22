// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_nutrients.dart';
import 'buddy_serving.dart';

part 'buddy_personal_food.freezed.dart';
part 'buddy_personal_food.g.dart';

@Freezed()
abstract class BuddyPersonalFood with _$BuddyPersonalFood {
  const factory BuddyPersonalFood({
    required String id,
    required List<String> names,
    required List<String> aliases,
    required String state,
    required BuddyNutrients nutrients,
    required List<BuddyServing> servings,
  }) = _BuddyPersonalFood;

  factory BuddyPersonalFood.fromJson(Map<String, Object?> json) =>
      _$BuddyPersonalFoodFromJson(json);
}
