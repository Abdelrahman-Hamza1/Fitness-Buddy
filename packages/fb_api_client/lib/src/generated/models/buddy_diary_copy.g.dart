// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_diary_copy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDiaryCopy _$BuddyDiaryCopyFromJson(Map<String, dynamic> json) =>
    _BuddyDiaryCopy(
      kind: BuddyDiaryCopyKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      source: BuddyDayHint.fromJson(json['source'] as Map<String, dynamic>),
      target: BuddyDayHint.fromJson(json['target'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyDiaryCopyToJson(_BuddyDiaryCopy instance) =>
    <String, dynamic>{
      'kind': _$BuddyDiaryCopyKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'source': instance.source.toJson(),
      'target': instance.target.toJson(),
    };

const _$BuddyDiaryCopyKindEnumMap = {
  BuddyDiaryCopyKind.diaryCopy: 'diaryCopy',
  BuddyDiaryCopyKind.$unknown: r'$unknown',
};
