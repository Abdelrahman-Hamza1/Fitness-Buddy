// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_ambiguous_reference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyAmbiguousReference _$BuddyAmbiguousReferenceFromJson(
  Map<String, dynamic> json,
) => _BuddyAmbiguousReference(
  kind: BuddyAmbiguousReferenceKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  operation: BuddyReferenceOperation.fromJson(json['operation'] as String),
  candidates: (json['candidates'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  reference: BuddyEntryReference.fromJson(
    json['reference'] as Map<String, dynamic>,
  ),
  patch: json['patch'] == null
      ? null
      : BuddyDiaryPatch.fromJson(json['patch'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyAmbiguousReferenceToJson(
  _BuddyAmbiguousReference instance,
) => <String, dynamic>{
  'kind': _$BuddyAmbiguousReferenceKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'operation': _$BuddyReferenceOperationEnumMap[instance.operation]!,
  'candidates': instance.candidates,
  'reference': instance.reference.toJson(),
  'patch': instance.patch?.toJson(),
};

const _$BuddyAmbiguousReferenceKindEnumMap = {
  BuddyAmbiguousReferenceKind.ambiguousReference: 'ambiguousReference',
  BuddyAmbiguousReferenceKind.$unknown: r'$unknown',
};

const _$BuddyReferenceOperationEnumMap = {
  BuddyReferenceOperation.edit: 'edit',
  BuddyReferenceOperation.delete: 'delete',
  BuddyReferenceOperation.$unknown: r'$unknown',
};
