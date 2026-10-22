// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_dimension.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDimension _$BuddyDimensionFromJson(Map<String, dynamic> json) =>
    _BuddyDimension(
      kind: json['kind'] as String,
      statedValue: json['statedValue'] as String?,
      options: (json['options'] as List<dynamic>)
          .map((e) => BuddyDimensionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyDimensionToJson(_BuddyDimension instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'statedValue': instance.statedValue,
      'options': instance.options.map((e) => e.toJson()).toList(),
    };
