// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

@Freezed()
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String userId,
    required bool isAnonymous,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required DateTime refreshExpiresAt,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, Object?> json) =>
      _$AuthTokensFromJson(json);
}
