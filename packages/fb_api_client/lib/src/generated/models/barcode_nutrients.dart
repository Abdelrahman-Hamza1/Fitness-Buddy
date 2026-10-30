// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'barcode_nutrients.freezed.dart';
part 'barcode_nutrients.g.dart';

@Freezed()
abstract class BarcodeNutrients with _$BarcodeNutrients {
  const factory BarcodeNutrients({
    required double? kcal,
    required double? proteinG,
    required double? carbsG,
    required double? fatG,
    required double? fiberG,
  }) = _BarcodeNutrients;

  factory BarcodeNutrients.fromJson(Map<String, Object?> json) =>
      _$BarcodeNutrientsFromJson(json);
}
