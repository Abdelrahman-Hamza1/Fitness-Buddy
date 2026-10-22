// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_food_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyFoodLog _$BuddyFoodLogFromJson(Map<String, dynamic> json) =>
    _BuddyFoodLog(
      kind: BuddyFoodLogKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      timeHint: json['timeHint'] as String?,
      slotHint: json['slotHint'] as String?,
      dishGroup: json['dishGroup'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => BuddyFoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyFoodLogToJson(_BuddyFoodLog instance) =>
    <String, dynamic>{
      'kind': _$BuddyFoodLogKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'timeHint': instance.timeHint,
      'slotHint': instance.slotHint,
      'dishGroup': instance.dishGroup,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$BuddyFoodLogKindEnumMap = {
  BuddyFoodLogKind.foodLog: 'foodLog',
  BuddyFoodLogKind.$unknown: r'$unknown',
};
