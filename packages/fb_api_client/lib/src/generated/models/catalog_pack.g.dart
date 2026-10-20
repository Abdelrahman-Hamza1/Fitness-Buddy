// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogPack _$CatalogPackFromJson(Map<String, dynamic> json) => _CatalogPack(
  version: (json['version'] as num).toInt(),
  url: json['url'] as String,
  sha256: json['sha256'] as String,
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  schemaVersion: (json['schemaVersion'] as num).toInt(),
);

Map<String, dynamic> _$CatalogPackToJson(_CatalogPack instance) =>
    <String, dynamic>{
      'version': instance.version,
      'url': instance.url,
      'sha256': instance.sha256,
      'sizeBytes': instance.sizeBytes,
      'schemaVersion': instance.schemaVersion,
    };
