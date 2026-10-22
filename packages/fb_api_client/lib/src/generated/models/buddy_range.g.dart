// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_range.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyRange _$BuddyRangeFromJson(Map<String, dynamic> json) => _BuddyRange(
  low: BuddyNutrients.fromJson(json['low'] as Map<String, dynamic>),
  high: BuddyNutrients.fromJson(json['high'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyRangeToJson(_BuddyRange instance) =>
    <String, dynamic>{
      'low': instance.low.toJson(),
      'high': instance.high.toJson(),
    };
