// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_out_of_scope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyOutOfScope _$BuddyOutOfScopeFromJson(Map<String, dynamic> json) =>
    _BuddyOutOfScope(
      kind: BuddyOutOfScopeKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$BuddyOutOfScopeToJson(_BuddyOutOfScope instance) =>
    <String, dynamic>{
      'kind': _$BuddyOutOfScopeKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'reason': instance.reason,
    };

const _$BuddyOutOfScopeKindEnumMap = {
  BuddyOutOfScopeKind.outOfScope: 'outOfScope',
  BuddyOutOfScopeKind.$unknown: r'$unknown',
};
