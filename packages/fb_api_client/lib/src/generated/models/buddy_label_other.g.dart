// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_label_other.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyLabelOther _$BuddyLabelOtherFromJson(Map<String, dynamic> json) =>
    _BuddyLabelOther(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      confidence: BuddyLabelConfidence.fromJson(json['confidence'] as String),
    );

Map<String, dynamic> _$BuddyLabelOtherToJson(_BuddyLabelOther instance) =>
    <String, dynamic>{
      'name': instance.name,
      'value': instance.value,
      'unit': instance.unit,
      'confidence': _$BuddyLabelConfidenceEnumMap[instance.confidence]!,
    };

const _$BuddyLabelConfidenceEnumMap = {
  BuddyLabelConfidence.high: 'high',
  BuddyLabelConfidence.medium: 'medium',
  BuddyLabelConfidence.low: 'low',
  BuddyLabelConfidence.$unknown: r'$unknown',
};
