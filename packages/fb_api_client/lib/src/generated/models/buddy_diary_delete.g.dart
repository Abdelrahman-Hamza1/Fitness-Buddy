// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_diary_delete.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDiaryDelete _$BuddyDiaryDeleteFromJson(Map<String, dynamic> json) =>
    _BuddyDiaryDelete(
      kind: BuddyDiaryDeleteKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      targets: (json['targets'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      reference: BuddyEntryReference.fromJson(
        json['reference'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$BuddyDiaryDeleteToJson(_BuddyDiaryDelete instance) =>
    <String, dynamic>{
      'kind': _$BuddyDiaryDeleteKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'targets': instance.targets,
      'reference': instance.reference.toJson(),
    };

const _$BuddyDiaryDeleteKindEnumMap = {
  BuddyDiaryDeleteKind.diaryDelete: 'diaryDelete',
  BuddyDiaryDeleteKind.$unknown: r'$unknown',
};
