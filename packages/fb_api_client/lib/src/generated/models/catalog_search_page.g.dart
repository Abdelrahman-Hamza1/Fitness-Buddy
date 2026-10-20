// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_search_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogSearchPage _$CatalogSearchPageFromJson(Map<String, dynamic> json) =>
    _CatalogSearchPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => CatalogFood.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$CatalogSearchPageToJson(_CatalogSearchPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
