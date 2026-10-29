// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_food_item.dart';
import 'buddy_intent.dart';
import 'buddy_personal_food_create_kind.dart';
import 'buddy_stated_nutrients.dart';

part 'buddy_personal_food_create.freezed.dart';
part 'buddy_personal_food_create.g.dart';

/// Create a personal food (AI-054). At least one of non-empty components or non-null stated; components are the main path.
@Freezed()
abstract class BuddyPersonalFoodCreate with _$BuddyPersonalFoodCreate {
  const factory BuddyPersonalFoodCreate({
    required BuddyPersonalFoodCreateKind kind,
    required String language,
    required String script,
    required String name,
    required List<String> aliases,

    /// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
    required List<BuddyFoodItem> components,
    required BuddyStatedNutrients? stated,
  }) = _BuddyPersonalFoodCreate;

  factory BuddyPersonalFoodCreate.fromJson(Map<String, Object?> json) =>
      _$BuddyPersonalFoodCreateFromJson(json);
}
