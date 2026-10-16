// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_push_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncPushRequest _$SyncPushRequestFromJson(Map<String, dynamic> json) =>
    _SyncPushRequest(
      changes: (json['changes'] as List<dynamic>)
          .map((e) => SyncChange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SyncPushRequestToJson(_SyncPushRequest instance) =>
    <String, dynamic>{
      'changes': instance.changes.map((e) => e.toJson()).toList(),
    };
