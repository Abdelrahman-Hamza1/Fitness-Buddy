// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_saved_meal_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddySavedMealCreate _$BuddySavedMealCreateFromJson(
  Map<String, dynamic> json,
) => _BuddySavedMealCreate(
  kind: BuddySavedMealCreateKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  name: json['name'] as String,
  activeProposal: json['activeProposal'] as String?,
  targets: (json['targets'] as List<dynamic>).map((e) => e as String).toList(),
  source: json['source'] == null
      ? null
      : BuddyDayHint.fromJson(json['source'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddySavedMealCreateToJson(
  _BuddySavedMealCreate instance,
) => <String, dynamic>{
  'kind': _$BuddySavedMealCreateKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'name': instance.name,
  'activeProposal': instance.activeProposal,
  'targets': instance.targets,
  'source': instance.source?.toJson(),
};

const _$BuddySavedMealCreateKindEnumMap = {
  BuddySavedMealCreateKind.savedMealCreate: 'savedMealCreate',
  BuddySavedMealCreateKind.$unknown: r'$unknown',
};
