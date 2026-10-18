// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'json_web_key.freezed.dart';
part 'json_web_key.g.dart';

@Freezed()
abstract class JsonWebKey with _$JsonWebKey {
  const factory JsonWebKey({
    required String kty,
    required String crv,
    required String kid,
    required String x,
    required String y,
    required String alg,
    required String use,
  }) = _JsonWebKey;

  factory JsonWebKey.fromJson(Map<String, Object?> json) =>
      _$JsonWebKeyFromJson(json);
}
