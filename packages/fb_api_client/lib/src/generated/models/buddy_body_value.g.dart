// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_body_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyBodyValue _$BuddyBodyValueFromJson(Map<String, dynamic> json) =>
    _BuddyBodyValue(
      date: json['date'] as String,
      metric: json['metric'] as String,
      value: (json['value'] as num).toDouble(),
      unit: BuddyBodyUnit.fromJson(json['unit'] as String),
    );

Map<String, dynamic> _$BuddyBodyValueToJson(_BuddyBodyValue instance) =>
    <String, dynamic>{
      'date': instance.date,
      'metric': instance.metric,
      'value': instance.value,
      'unit': _$BuddyBodyUnitEnumMap[instance.unit]!,
    };

const _$BuddyBodyUnitEnumMap = {
  BuddyBodyUnit.kg: 'kg',
  BuddyBodyUnit.cm: 'cm',
  BuddyBodyUnit.percent: 'percent',
  BuddyBodyUnit.$unknown: r'$unknown',
};
