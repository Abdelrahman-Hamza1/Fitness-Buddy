// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_label_value.dart';

part 'buddy_label_nutrients.freezed.dart';
part 'buddy_label_nutrients.g.dart';

/// Nutrients on the label's basis (kcal; grams, or milligrams for sodium and cholesterol).
@Freezed()
abstract class BuddyLabelNutrients with _$BuddyLabelNutrients {
  const factory BuddyLabelNutrients({
    required BuddyLabelValue kcal,
    required BuddyLabelValue proteinG,
    required BuddyLabelValue carbsG,
    required BuddyLabelValue fatG,
    required BuddyLabelValue fiberG,
    required BuddyLabelValue sugarG,
    required BuddyLabelValue saturatedFatG,
    required BuddyLabelValue transFatG,
    required BuddyLabelValue sodiumMg,
    required BuddyLabelValue cholesterolMg,

    /// The label gave only kJ; code converted it (÷ 4.184).
    required bool kcalFromKj,

    /// The label gave salt; code converted it to sodium (× 400 mg per g).
    required bool sodiumFromSalt,
  }) = _BuddyLabelNutrients;

  factory BuddyLabelNutrients.fromJson(Map<String, Object?> json) =>
      _$BuddyLabelNutrientsFromJson(json);
}
