// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_web_key_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JsonWebKeySet _$JsonWebKeySetFromJson(Map<String, dynamic> json) =>
    _JsonWebKeySet(
      keys: (json['keys'] as List<dynamic>)
          .map((e) => JsonWebKey.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JsonWebKeySetToJson(_JsonWebKeySet instance) =>
    <String, dynamic>{'keys': instance.keys.map((e) => e.toJson()).toList()};
