// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_weight_trend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWeightTrend _$BuddyWeightTrendFromJson(Map<String, dynamic> json) =>
    _BuddyWeightTrend(
      from: json['from'] as String,
      to: json['to'] as String,
      startKg: (json['startKg'] as num).toDouble(),
      endKg: (json['endKg'] as num).toDouble(),
      changeKg: (json['changeKg'] as num).toDouble(),
      weeklyChangeKg: (json['weeklyChangeKg'] as num?)?.toDouble(),
      weighIns: (json['weighIns'] as num).toInt(),
    );

Map<String, dynamic> _$BuddyWeightTrendToJson(_BuddyWeightTrend instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'startKg': instance.startKg,
      'endKg': instance.endKg,
      'changeKg': instance.changeKg,
      'weeklyChangeKg': instance.weeklyChangeKg,
      'weighIns': instance.weighIns,
    };
