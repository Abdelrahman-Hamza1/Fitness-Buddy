// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_batch_portion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyBatchPortion _$BuddyBatchPortionFromJson(Map<String, dynamic> json) =>
    _BuddyBatchPortion(
      kind: BuddyBatchPortionKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      batchId: json['batchId'] as String,
      portion: json['portion'] == null
          ? null
          : BuddyPortion.fromJson(json['portion'] as Map<String, dynamic>),
      rest: json['rest'] as bool,
      timeHint: json['timeHint'] as String?,
      slotHint: json['slotHint'] as String?,
      dateHint: json['dateHint'] as String?,
    );

Map<String, dynamic> _$BuddyBatchPortionToJson(_BuddyBatchPortion instance) =>
    <String, dynamic>{
      'kind': _$BuddyBatchPortionKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'batchId': instance.batchId,
      'portion': instance.portion?.toJson(),
      'rest': instance.rest,
      'timeHint': instance.timeHint,
      'slotHint': instance.slotHint,
      'dateHint': instance.dateHint,
    };

const _$BuddyBatchPortionKindEnumMap = {
  BuddyBatchPortionKind.batchPortion: 'batchPortion',
  BuddyBatchPortionKind.$unknown: r'$unknown',
};
