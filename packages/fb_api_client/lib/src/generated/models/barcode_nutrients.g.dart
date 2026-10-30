// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_nutrients.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BarcodeNutrients _$BarcodeNutrientsFromJson(Map<String, dynamic> json) =>
    _BarcodeNutrients(
      kcal: (json['kcal'] as num?)?.toDouble(),
      proteinG: (json['proteinG'] as num?)?.toDouble(),
      carbsG: (json['carbsG'] as num?)?.toDouble(),
      fatG: (json['fatG'] as num?)?.toDouble(),
      fiberG: (json['fiberG'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BarcodeNutrientsToJson(_BarcodeNutrients instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
      'fiberG': instance.fiberG,
    };
