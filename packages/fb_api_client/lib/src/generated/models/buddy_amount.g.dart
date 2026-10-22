// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_amount.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyAmount _$BuddyAmountFromJson(Map<String, dynamic> json) => _BuddyAmount(
  value: (json['value'] as num?)?.toDouble(),
  unit: json['unit'] as String?,
  explicit: json['explicit'] as bool,
);

Map<String, dynamic> _$BuddyAmountToJson(_BuddyAmount instance) =>
    <String, dynamic>{
      'value': instance.value,
      'unit': instance.unit,
      'explicit': instance.explicit,
    };
