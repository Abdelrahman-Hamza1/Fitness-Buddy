// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BarcodeProduct _$BarcodeProductFromJson(Map<String, dynamic> json) =>
    _BarcodeProduct(
      code: json['code'] as String,
      source: json['source'] as String,
      complete: json['complete'] as bool,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      brand: json['brand'] as String?,
      basis: json['basis'] as String,
      per100: BarcodeNutrients.fromJson(json['per100'] as Map<String, dynamic>),
      servingQuantity: (json['servingQuantity'] as num?)?.toDouble(),
      servingLabel: json['servingLabel'] as String?,
      ingredientsText: json['ingredientsText'] as String?,
      labels: (json['labels'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$BarcodeProductToJson(_BarcodeProduct instance) =>
    <String, dynamic>{
      'code': instance.code,
      'source': instance.source,
      'complete': instance.complete,
      'name': instance.name,
      'nameAr': instance.nameAr,
      'brand': instance.brand,
      'basis': instance.basis,
      'per100': instance.per100.toJson(),
      'servingQuantity': instance.servingQuantity,
      'servingLabel': instance.servingLabel,
      'ingredientsText': instance.ingredientsText,
      'labels': instance.labels,
    };
