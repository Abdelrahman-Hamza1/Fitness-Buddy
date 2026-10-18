// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  userId: json['userId'] as String,
  isAnonymous: json['isAnonymous'] as bool,
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  refreshExpiresAt: DateTime.parse(json['refreshExpiresAt'] as String),
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'isAnonymous': instance.isAnonymous,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'refreshExpiresAt': instance.refreshExpiresAt.toIso8601String(),
    };
