// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_clarify.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyClarify _$BuddyClarifyFromJson(Map<String, dynamic> json) =>
    _BuddyClarify(
      kind: BuddyClarifyKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$BuddyClarifyToJson(_BuddyClarify instance) =>
    <String, dynamic>{
      'kind': _$BuddyClarifyKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'reason': instance.reason,
    };

const _$BuddyClarifyKindEnumMap = {
  BuddyClarifyKind.clarify: 'clarify',
  BuddyClarifyKind.$unknown: r'$unknown',
};
