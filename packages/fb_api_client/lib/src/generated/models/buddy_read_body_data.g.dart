// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_body_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadBodyData _$BuddyReadBodyDataFromJson(Map<String, dynamic> json) =>
    _BuddyReadBodyData(
      values: (json['values'] as List<dynamic>)
          .map((e) => BuddyBodyValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      trend: json['trend'] == null
          ? null
          : BuddyWeightTrend.fromJson(json['trend'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyReadBodyDataToJson(_BuddyReadBodyData instance) =>
    <String, dynamic>{
      'values': instance.values.map((e) => e.toJson()).toList(),
      'trend': instance.trend?.toJson(),
    };
