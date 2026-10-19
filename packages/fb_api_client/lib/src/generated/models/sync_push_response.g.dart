// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_push_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncPushResponse _$SyncPushResponseFromJson(Map<String, dynamic> json) =>
    _SyncPushResponse(
      results: (json['results'] as List<dynamic>)
          .map((e) => SyncPushResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      serverTime: DateTime.parse(json['serverTime'] as String),
      datasetId: json['datasetId'] as String,
    );

Map<String, dynamic> _$SyncPushResponseToJson(_SyncPushResponse instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
      'serverTime': instance.serverTime.toIso8601String(),
      'datasetId': instance.datasetId,
    };
