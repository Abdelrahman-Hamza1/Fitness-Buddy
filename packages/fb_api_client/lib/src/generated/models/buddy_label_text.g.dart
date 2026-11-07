// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_label_text.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyLabelText _$BuddyLabelTextFromJson(Map<String, dynamic> json) =>
    _BuddyLabelText(
      value: json['value'] as String?,
      confidence: BuddyLabelConfidence.fromJson(json['confidence'] as String),
    );

Map<String, dynamic> _$BuddyLabelTextToJson(_BuddyLabelText instance) =>
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
