// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_nutrients.freezed.dart';
part 'catalog_nutrients.g.dart';

@Freezed()
abstract class CatalogNutrients with _$CatalogNutrients {
  const factory CatalogNutrients({
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required double fiberG,
  }) = _CatalogNutrients;

  factory CatalogNutrients.fromJson(Map<String, Object?> json) =>
      _$CatalogNutrientsFromJson(json);
}
