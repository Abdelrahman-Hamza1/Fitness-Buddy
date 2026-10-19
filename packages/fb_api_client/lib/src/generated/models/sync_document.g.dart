// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncDocument _$SyncDocumentFromJson(Map<String, dynamic> json) =>
    _SyncDocument(
      entity: json['entity'] as String,
      id: json['id'] as String,
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      hlc: json['hlc'] as String,
      deviceId: json['deviceId'] as String,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      payload: json['payload'] as Map<String, dynamic>,
      serverSeq: json['serverSeq'] as String,
      compacted: json['compacted'] as bool,
    );

Map<String, dynamic> _$SyncDocumentToJson(_SyncDocument instance) =>
    <String, dynamic>{
      'entity': instance.entity,
      'id': instance.id,
      'schemaVersion': instance.schemaVersion,
      'hlc': instance.hlc,
      'deviceId': instance.deviceId,
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'payload': instance.payload,
      'serverSeq': instance.serverSeq,
      'compacted': instance.compacted,
    };
