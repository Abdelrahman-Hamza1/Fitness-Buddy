// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_label_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyLabelValue _$BuddyLabelValueFromJson(Map<String, dynamic> json) =>
    _BuddyLabelValue(
      value: (json['value'] as num?)?.toDouble(),
      confidence: BuddyLabelConfidence.fromJson(json['confidence'] as String),
    );

Map<String, dynamic> _$BuddyLabelValueToJson(_BuddyLabelValue instance) =>
    <String, dynamic>{
      'value': instance.value,
      'confidence': _$BuddyLabelConfidenceEnumMap[instance.confidence]!,
    };

const _$BuddyLabelConfidenceEnumMap = {
  BuddyLabelConfidence.high: 'high',
  BuddyLabelConfidence.medium: 'medium',
  BuddyLabelConfidence.low: 'low',
  BuddyLabelConfidence.$unknown: r'$unknown',
};
