// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_label_nutrients.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyLabelNutrients _$BuddyLabelNutrientsFromJson(
  Map<String, dynamic> json,
) => _BuddyLabelNutrients(
  kcal: BuddyLabelValue.fromJson(json['kcal'] as Map<String, dynamic>),
  proteinG: BuddyLabelValue.fromJson(json['proteinG'] as Map<String, dynamic>),
  carbsG: BuddyLabelValue.fromJson(json['carbsG'] as Map<String, dynamic>),
  fatG: BuddyLabelValue.fromJson(json['fatG'] as Map<String, dynamic>),
  fiberG: BuddyLabelValue.fromJson(json['fiberG'] as Map<String, dynamic>),
  sugarG: BuddyLabelValue.fromJson(json['sugarG'] as Map<String, dynamic>),
  saturatedFatG: BuddyLabelValue.fromJson(
    json['saturatedFatG'] as Map<String, dynamic>,
  ),
  transFatG: BuddyLabelValue.fromJson(
    json['transFatG'] as Map<String, dynamic>,
  ),
  sodiumMg: BuddyLabelValue.fromJson(json['sodiumMg'] as Map<String, dynamic>),
  cholesterolMg: BuddyLabelValue.fromJson(
    json['cholesterolMg'] as Map<String, dynamic>,
  ),
  kcalFromKj: json['kcalFromKj'] as bool,
  sodiumFromSalt: json['sodiumFromSalt'] as bool,
);

Map<String, dynamic> _$BuddyLabelNutrientsToJson(
  _BuddyLabelNutrients instance,
) => <String, dynamic>{
  'kcal': instance.kcal.toJson(),
  'proteinG': instance.proteinG.toJson(),
  'carbsG': instance.carbsG.toJson(),
  'fatG': instance.fatG.toJson(),
  'fiberG': instance.fiberG.toJson(),
  'sugarG': instance.sugarG.toJson(),
  'saturatedFatG': instance.saturatedFatG.toJson(),
  'transFatG': instance.transFatG.toJson(),
  'sodiumMg': instance.sodiumMg.toJson(),
  'cholesterolMg': instance.cholesterolMg.toJson(),
  'kcalFromKj': instance.kcalFromKj,
  'sodiumFromSalt': instance.sodiumFromSalt,
};
