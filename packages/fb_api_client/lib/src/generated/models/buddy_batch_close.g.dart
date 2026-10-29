// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_batch_close.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyBatchClose _$BuddyBatchCloseFromJson(Map<String, dynamic> json) =>
    _BuddyBatchClose(
      kind: BuddyBatchCloseKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      batchId: json['batchId'] as String,
    );

Map<String, dynamic> _$BuddyBatchCloseToJson(_BuddyBatchClose instance) =>
    <String, dynamic>{
      'kind': _$BuddyBatchCloseKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'batchId': instance.batchId,
    };

const _$BuddyBatchCloseKindEnumMap = {
  BuddyBatchCloseKind.batchClose: 'batchClose',
  BuddyBatchCloseKind.$unknown: r'$unknown',
};
