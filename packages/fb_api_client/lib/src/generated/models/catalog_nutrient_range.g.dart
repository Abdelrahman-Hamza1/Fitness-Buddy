// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_nutrient_range.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogNutrientRange _$CatalogNutrientRangeFromJson(
  Map<String, dynamic> json,
) => _CatalogNutrientRange(
  low: CatalogNutrients.fromJson(json['low'] as Map<String, dynamic>),
  high: CatalogNutrients.fromJson(json['high'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CatalogNutrientRangeToJson(
  _CatalogNutrientRange instance,
) => <String, dynamic>{
  'low': instance.low.toJson(),
  'high': instance.high.toJson(),
};
