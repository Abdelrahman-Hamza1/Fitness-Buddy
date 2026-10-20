// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_nutrients.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogNutrients _$CatalogNutrientsFromJson(Map<String, dynamic> json) =>
    _CatalogNutrients(
      kcal: (json['kcal'] as num).toDouble(),
      proteinG: (json['proteinG'] as num).toDouble(),
      carbsG: (json['carbsG'] as num).toDouble(),
      fatG: (json['fatG'] as num).toDouble(),
      fiberG: (json['fiberG'] as num).toDouble(),
    );

Map<String, dynamic> _$CatalogNutrientsToJson(_CatalogNutrients instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
      'fiberG': instance.fiberG,
    };
