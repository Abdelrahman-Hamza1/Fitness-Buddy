// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_saved_meal_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddySavedMealLog _$BuddySavedMealLogFromJson(Map<String, dynamic> json) =>
    _BuddySavedMealLog(
      kind: BuddySavedMealLogKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      savedMealId: json['savedMealId'] as String,
      timeHint: json['timeHint'] as String?,
      slotHint: json['slotHint'] as String?,
      dateHint: json['dateHint'] as String?,
      share: json['share'] == null
          ? null
          : BuddyShare.fromJson(json['share'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddySavedMealLogToJson(_BuddySavedMealLog instance) =>
    <String, dynamic>{
      'kind': _$BuddySavedMealLogKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'savedMealId': instance.savedMealId,
      'timeHint': instance.timeHint,
      'slotHint': instance.slotHint,
      'dateHint': instance.dateHint,
      'share': instance.share?.toJson(),
    };

const _$BuddySavedMealLogKindEnumMap = {
  BuddySavedMealLogKind.savedMealLog: 'savedMealLog',
  BuddySavedMealLogKind.$unknown: r'$unknown',
};
