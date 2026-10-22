// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_medical.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyMedical _$BuddyMedicalFromJson(Map<String, dynamic> json) =>
    _BuddyMedical(
      kind: BuddyMedicalKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
    );

Map<String, dynamic> _$BuddyMedicalToJson(_BuddyMedical instance) =>
    <String, dynamic>{
      'kind': _$BuddyMedicalKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
    };

const _$BuddyMedicalKindEnumMap = {
  BuddyMedicalKind.medical: 'medical',
  BuddyMedicalKind.$unknown: r'$unknown',
};
