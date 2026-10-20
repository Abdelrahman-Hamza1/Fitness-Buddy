// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_nutrients.dart';

part 'catalog_nutrient_range.freezed.dart';
part 'catalog_nutrient_range.g.dart';

@Freezed()
abstract class CatalogNutrientRange with _$CatalogNutrientRange {
  const factory CatalogNutrientRange({
    required CatalogNutrients low,
    required CatalogNutrients high,
  }) = _CatalogNutrientRange;

  factory CatalogNutrientRange.fromJson(Map<String, Object?> json) =>
      _$CatalogNutrientRangeFromJson(json);
}
