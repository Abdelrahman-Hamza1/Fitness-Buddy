// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_web_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JsonWebKey _$JsonWebKeyFromJson(Map<String, dynamic> json) => _JsonWebKey(
  kty: json['kty'] as String,
  crv: json['crv'] as String,
  kid: json['kid'] as String,
  x: json['x'] as String,
  y: json['y'] as String,
  alg: json['alg'] as String,
  use: json['use'] as String,
);

Map<String, dynamic> _$JsonWebKeyToJson(_JsonWebKey instance) =>
    <String, dynamic>{
      'kty': instance.kty,
      'crv': instance.crv,
      'kid': instance.kid,
      'x': instance.x,
      'y': instance.y,
      'alg': instance.alg,
      'use': instance.use,
    };
