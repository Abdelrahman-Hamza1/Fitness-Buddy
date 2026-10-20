// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_serving.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogServing _$CatalogServingFromJson(Map<String, dynamic> json) =>
    _CatalogServing(
      unitCode: json['unitCode'] as String,
      g: (json['g'] as num?)?.toDouble(),
      ml: (json['ml'] as num?)?.toDouble(),
      rangeLo: (json['rangeLo'] as num?)?.toDouble(),
      rangeHi: (json['rangeHi'] as num?)?.toDouble(),
      source: json['source'] as String,
    );

Map<String, dynamic> _$CatalogServingToJson(_CatalogServing instance) =>
    <String, dynamic>{
      'unitCode': instance.unitCode,
      'g': instance.g,
      'ml': instance.ml,
      'rangeLo': instance.rangeLo,
      'rangeHi': instance.rangeHi,
      'source': instance.source,
    };
