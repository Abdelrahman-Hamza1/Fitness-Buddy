// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_serving.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyServing _$BuddyServingFromJson(Map<String, dynamic> json) =>
    _BuddyServing(
      unitCode: json['unitCode'] as String,
      g: (json['g'] as num?)?.toDouble(),
      ml: (json['ml'] as num?)?.toDouble(),
      rangeLo: (json['rangeLo'] as num?)?.toDouble(),
      rangeHi: (json['rangeHi'] as num?)?.toDouble(),
      source: json['source'] as String,
    );

Map<String, dynamic> _$BuddyServingToJson(_BuddyServing instance) =>
    <String, dynamic>{
      'unitCode': instance.unitCode,
      'g': instance.g,
      'ml': instance.ml,
      'rangeLo': instance.rangeLo,
      'rangeHi': instance.rangeHi,
      'source': instance.source,
    };
