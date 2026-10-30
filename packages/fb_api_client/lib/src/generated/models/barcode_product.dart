// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'barcode_nutrients.dart';

part 'barcode_product.freezed.dart';
part 'barcode_product.g.dart';

@Freezed()
abstract class BarcodeProduct with _$BarcodeProduct {
  const factory BarcodeProduct({
    required String code,
    required String source,
    required bool complete,
    required String? name,
    required String? nameAr,
    required String? brand,
    required String basis,
    required BarcodeNutrients per100,
    required double? servingQuantity,
    required String? servingLabel,
    required String? ingredientsText,
    required List<String> labels,
  }) = _BarcodeProduct;

  factory BarcodeProduct.fromJson(Map<String, Object?> json) =>
      _$BarcodeProductFromJson(json);
}
