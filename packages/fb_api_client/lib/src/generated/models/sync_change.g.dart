// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_change.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncChange _$SyncChangeFromJson(Map<String, dynamic> json) => _SyncChange(
  entity: json['entity'] as String,
  id: json['id'] as String,
  schemaVersion: (json['schemaVersion'] as num).toInt(),
  hlc: json['hlc'] as String,
  deviceId: json['deviceId'] as String,
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  payload: json['payload'] as Map<String, dynamic>,
);

Map<String, dynamic> _$SyncChangeToJson(_SyncChange instance) =>
    <String, dynamic>{
      'entity': instance.entity,
      'id': instance.id,
      'schemaVersion': instance.schemaVersion,
      'hlc': instance.hlc,
      'deviceId': instance.deviceId,
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'payload': instance.payload,
    };
