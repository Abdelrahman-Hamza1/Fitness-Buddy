// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_pack.freezed.dart';
part 'catalog_pack.g.dart';

@Freezed()
abstract class CatalogPack with _$CatalogPack {
  const factory CatalogPack({
    required int version,
    required String url,
    required String sha256,
    required int sizeBytes,
    required int schemaVersion,
  }) = _CatalogPack;

  factory CatalogPack.fromJson(Map<String, Object?> json) =>
      _$CatalogPackFromJson(json);
}
