// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_push_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncPushResult _$SyncPushResultFromJson(Map<String, dynamic> json) =>
    _SyncPushResult(
      entity: json['entity'] as String,
      id: json['id'] as String,
      hlc: json['hlc'] as String,
      status: json['status'] as String,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$SyncPushResultToJson(_SyncPushResult instance) =>
    <String, dynamic>{
      'entity': instance.entity,
      'id': instance.id,
      'hlc': instance.hlc,
      'status': instance.status,
      'reason': instance.reason,
    };
