// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyBatch _$BuddyBatchFromJson(Map<String, dynamic> json) => _BuddyBatch(
  kind: BuddyBatchKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  name: json['name'] as String?,
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => BuddyFoodItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  cookedWeight: json['cookedWeight'] == null
      ? null
      : BuddyAmount.fromJson(json['cookedWeight'] as Map<String, dynamic>),
  path: json['path'] == null
      ? null
      : BuddyBatchPath.fromJson(json['path'] as String),
  eatenNow: json['eatenNow'] == null
      ? null
      : BuddyPortion.fromJson(json['eatenNow'] as Map<String, dynamic>),
  timeHint: json['timeHint'] as String?,
  slotHint: json['slotHint'] as String?,
  dateHint: json['dateHint'] as String?,
);

Map<String, dynamic> _$BuddyBatchToJson(_BuddyBatch instance) =>
    <String, dynamic>{
      'kind': _$BuddyBatchKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'name': instance.name,
      'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
      'cookedWeight': instance.cookedWeight?.toJson(),
      'path': _$BuddyBatchPathEnumMap[instance.path],
      'eatenNow': instance.eatenNow?.toJson(),
      'timeHint': instance.timeHint,
      'slotHint': instance.slotHint,
      'dateHint': instance.dateHint,
    };

const _$BuddyBatchKindEnumMap = {
  BuddyBatchKind.batch: 'batch',
  BuddyBatchKind.$unknown: r'$unknown',
};

const _$BuddyBatchPathEnumMap = {
  BuddyBatchPath.quick: 'quick',
  BuddyBatchPath.leftovers: 'leftovers',
  BuddyBatchPath.$unknown: r'$unknown',
};
