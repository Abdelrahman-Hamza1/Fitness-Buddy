// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_dimension_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDimensionOption _$BuddyDimensionOptionFromJson(
  Map<String, dynamic> json,
) => _BuddyDimensionOption(
  value: json['value'] as String,
  candidateKey: json['candidateKey'] as String?,
  amount: (json['amount'] as num?)?.toDouble(),
  unit: json['unit'] as String?,
  candidate: json['candidate'] == null
      ? null
      : BuddyCandidate.fromJson(json['candidate'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyDimensionOptionToJson(
  _BuddyDimensionOption instance,
) => <String, dynamic>{
  'value': instance.value,
  'candidateKey': instance.candidateKey,
  'amount': instance.amount,
  'unit': instance.unit,
  'candidate': instance.candidate?.toJson(),
};
