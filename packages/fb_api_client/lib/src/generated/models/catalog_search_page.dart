// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_food.dart';

part 'catalog_search_page.freezed.dart';
part 'catalog_search_page.g.dart';

@Freezed()
abstract class CatalogSearchPage with _$CatalogSearchPage {
  const factory CatalogSearchPage({
    required List<CatalogFood> items,
    required String? nextCursor,
  }) = _CatalogSearchPage;

  factory CatalogSearchPage.fromJson(Map<String, Object?> json) =>
      _$CatalogSearchPageFromJson(json);
}
