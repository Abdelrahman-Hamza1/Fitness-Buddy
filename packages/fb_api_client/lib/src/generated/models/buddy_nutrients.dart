// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_nutrients.freezed.dart';
part 'buddy_nutrients.g.dart';

@Freezed()
abstract class BuddyNutrients with _$BuddyNutrients {
  const factory BuddyNutrients({
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required double fiberG,
  }) = _BuddyNutrients;

  factory BuddyNutrients.fromJson(Map<String, Object?> json) =>
      _$BuddyNutrientsFromJson(json);
}
