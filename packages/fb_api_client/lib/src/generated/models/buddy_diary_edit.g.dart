// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_diary_edit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDiaryEdit _$BuddyDiaryEditFromJson(Map<String, dynamic> json) =>
    _BuddyDiaryEdit(
      kind: BuddyDiaryEditKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      targets: (json['targets'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      reference: BuddyEntryReference.fromJson(
        json['reference'] as Map<String, dynamic>,
      ),
      patch: BuddyDiaryPatch.fromJson(json['patch'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyDiaryEditToJson(_BuddyDiaryEdit instance) =>
    <String, dynamic>{
      'kind': _$BuddyDiaryEditKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'targets': instance.targets,
      'reference': instance.reference.toJson(),
      'patch': instance.patch.toJson(),
    };

const _$BuddyDiaryEditKindEnumMap = {
  BuddyDiaryEditKind.diaryEdit: 'diaryEdit',
  BuddyDiaryEditKind.$unknown: r'$unknown',
};
