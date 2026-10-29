// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_nutrient_basis.dart';

part 'buddy_stated_nutrients.freezed.dart';
part 'buddy_stated_nutrients.g.dart';

/// Transcribed user figures (TD-092): each non-null value appears literally in the message. Never computed or filled by the server; the app reviews them in the personal-food form. Bounds match the request side (nutrients 0-10000, serving sizes up to 100000).
@Freezed()
abstract class BuddyStatedNutrients with _$BuddyStatedNutrients {
  const factory BuddyStatedNutrients({
    required BuddyNutrientBasis basis,
    required double? servingG,
    required double? servingMl,
    required double? kcal,
    required double? proteinG,
    required double? carbsG,
    required double? fatG,
    required double? fiberG,
  }) = _BuddyStatedNutrients;

  factory BuddyStatedNutrients.fromJson(Map<String, Object?> json) =>
      _$BuddyStatedNutrientsFromJson(json);
}
