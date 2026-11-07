// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_label_serving.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyLabelServing _$BuddyLabelServingFromJson(Map<String, dynamic> json) =>
    _BuddyLabelServing(
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      g: (json['g'] as num?)?.toDouble(),
      ml: (json['ml'] as num?)?.toDouble(),
      label: json['label'] as String?,
      confidence: BuddyLabelConfidence.fromJson(json['confidence'] as String),
    );

Map<String, dynamic> _$BuddyLabelServingToJson(_BuddyLabelServing instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'unit': instance.unit,
      'g': instance.g,
      'ml': instance.ml,
      'label': instance.label,
      'confidence': _$BuddyLabelConfidenceEnumMap[instance.confidence]!,
    };

const _$BuddyLabelConfidenceEnumMap = {
  BuddyLabelConfidence.high: 'high',
  BuddyLabelConfidence.medium: 'medium',
  BuddyLabelConfidence.low: 'low',
  BuddyLabelConfidence.$unknown: r'$unknown',
};
