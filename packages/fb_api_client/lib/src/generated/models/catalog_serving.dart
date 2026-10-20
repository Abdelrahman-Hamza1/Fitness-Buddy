// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_serving.freezed.dart';
part 'catalog_serving.g.dart';

@Freezed()
abstract class CatalogServing with _$CatalogServing {
  const factory CatalogServing({
    required String unitCode,
    required double? g,
    required double? ml,
    required double? rangeLo,
    required double? rangeHi,
    required String source,
  }) = _CatalogServing;

  factory CatalogServing.fromJson(Map<String, Object?> json) =>
      _$CatalogServingFromJson(json);
}
