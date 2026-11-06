// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_nutrients_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyNutrientsRequest _$BuddyNutrientsRequestFromJson(
  Map<String, dynamic> json,
) => _BuddyNutrientsRequest(
  kcal: (json['kcal'] as num).toDouble(),
  proteinG: (json['proteinG'] as num).toDouble(),
  carbsG: (json['carbsG'] as num).toDouble(),
  fatG: (json['fatG'] as num).toDouble(),
  fiberG: (json['fiberG'] as num).toDouble(),
);

Map<String, dynamic> _$BuddyNutrientsRequestToJson(
  _BuddyNutrientsRequest instance,
) => <String, dynamic>{
  'kcal': instance.kcal,
  'proteinG': instance.proteinG,
  'carbsG': instance.carbsG,
  'fatG': instance.fatG,
  'fiberG': instance.fiberG,
};
