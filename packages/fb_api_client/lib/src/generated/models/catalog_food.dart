// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_nutrient_range.dart';
import 'catalog_nutrients.dart';
import 'catalog_serving.dart';

part 'catalog_food.freezed.dart';
part 'catalog_food.g.dart';

@Freezed()
abstract class CatalogFood with _$CatalogFood {
  const factory CatalogFood({
    required String kind,
    required String source,
    required String? sourceRef,
    required String nameEn,
    required String? nameAr,
    required String state,
    required bool verified,
    required int catalogVersion,
    required CatalogNutrients nutrients,
    required CatalogNutrientRange? ranges,
    required Map<String, double>? extras,
    required double? densityGPerMl,
    required String? yieldGroup,
    required List<CatalogServing> servings,
    required String catalogKey,
  }) = _CatalogFood;

  factory CatalogFood.fromJson(Map<String, Object?> json) =>
      _$CatalogFoodFromJson(json);
}
