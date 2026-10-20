// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_food.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogFood _$CatalogFoodFromJson(Map<String, dynamic> json) => _CatalogFood(
  kind: json['kind'] as String,
  source: json['source'] as String,
  sourceRef: json['sourceRef'] as String?,
  nameEn: json['nameEn'] as String,
  nameAr: json['nameAr'] as String?,
  state: json['state'] as String,
  verified: json['verified'] as bool,
  catalogVersion: (json['catalogVersion'] as num).toInt(),
  nutrients: CatalogNutrients.fromJson(
    json['nutrients'] as Map<String, dynamic>,
  ),
  ranges: json['ranges'] == null
      ? null
      : CatalogNutrientRange.fromJson(json['ranges'] as Map<String, dynamic>),
  extras: (json['extras'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  densityGPerMl: (json['densityGPerMl'] as num?)?.toDouble(),
  yieldGroup: json['yieldGroup'] as String?,
  servings: (json['servings'] as List<dynamic>)
      .map((e) => CatalogServing.fromJson(e as Map<String, dynamic>))
      .toList(),
  catalogKey: json['catalogKey'] as String,
);

Map<String, dynamic> _$CatalogFoodToJson(_CatalogFood instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'source': instance.source,
      'sourceRef': instance.sourceRef,
      'nameEn': instance.nameEn,
      'nameAr': instance.nameAr,
      'state': instance.state,
      'verified': instance.verified,
      'catalogVersion': instance.catalogVersion,
      'nutrients': instance.nutrients.toJson(),
      'ranges': instance.ranges?.toJson(),
      'extras': instance.extras,
      'densityGPerMl': instance.densityGPerMl,
      'yieldGroup': instance.yieldGroup,
      'servings': instance.servings.map((e) => e.toJson()).toList(),
      'catalogKey': instance.catalogKey,
    };
