// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_stated_nutrients.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyStatedNutrients _$BuddyStatedNutrientsFromJson(
  Map<String, dynamic> json,
) => _BuddyStatedNutrients(
  basis: BuddyNutrientBasis.fromJson(json['basis'] as String),
  servingG: (json['servingG'] as num?)?.toDouble(),
  servingMl: (json['servingMl'] as num?)?.toDouble(),
  kcal: (json['kcal'] as num?)?.toDouble(),
  proteinG: (json['proteinG'] as num?)?.toDouble(),
  carbsG: (json['carbsG'] as num?)?.toDouble(),
  fatG: (json['fatG'] as num?)?.toDouble(),
  fiberG: (json['fiberG'] as num?)?.toDouble(),
);

Map<String, dynamic> _$BuddyStatedNutrientsToJson(
  _BuddyStatedNutrients instance,
) => <String, dynamic>{
  'basis': _$BuddyNutrientBasisEnumMap[instance.basis]!,
  'servingG': instance.servingG,
  'servingMl': instance.servingMl,
  'kcal': instance.kcal,
  'proteinG': instance.proteinG,
  'carbsG': instance.carbsG,
  'fatG': instance.fatG,
  'fiberG': instance.fiberG,
};

const _$BuddyNutrientBasisEnumMap = {
  BuddyNutrientBasis.per100g: 'per100g',
  BuddyNutrientBasis.per100ml: 'per100ml',
  BuddyNutrientBasis.perServing: 'perServing',
  BuddyNutrientBasis.$unknown: r'$unknown',
};
