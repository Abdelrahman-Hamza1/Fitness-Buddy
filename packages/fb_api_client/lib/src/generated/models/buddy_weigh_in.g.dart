// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_weigh_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWeighIn _$BuddyWeighInFromJson(Map<String, dynamic> json) =>
    _BuddyWeighIn(
      kind: BuddyWeighInKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timeHint: json['timeHint'] as String?,
      dateHint: json['dateHint'] as String?,
    );

Map<String, dynamic> _$BuddyWeighInToJson(_BuddyWeighIn instance) =>
    <String, dynamic>{
      'kind': _$BuddyWeighInKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'value': instance.value,
      'unit': instance.unit,
      'timeHint': instance.timeHint,
      'dateHint': instance.dateHint,
    };

const _$BuddyWeighInKindEnumMap = {
  BuddyWeighInKind.weighIn: 'weighIn',
  BuddyWeighInKind.$unknown: r'$unknown',
};
