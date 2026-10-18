// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_web_key.dart';

part 'json_web_key_set.freezed.dart';
part 'json_web_key_set.g.dart';

@Freezed()
abstract class JsonWebKeySet with _$JsonWebKeySet {
  const factory JsonWebKeySet({required List<JsonWebKey> keys}) =
      _JsonWebKeySet;

  factory JsonWebKeySet.fromJson(Map<String, Object?> json) =>
      _$JsonWebKeySetFromJson(json);
}
