// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClientConfig _$ClientConfigFromJson(Map<String, dynamic> json) =>
    _ClientConfig(
      minimumAppVersion: json['minimumAppVersion'] as String,
      featureFlags: Map<String, bool>.from(json['featureFlags'] as Map),
      thresholds: (json['thresholds'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$ClientConfigToJson(_ClientConfig instance) =>
    <String, dynamic>{
      'minimumAppVersion': instance.minimumAppVersion,
      'featureFlags': instance.featureFlags,
      'thresholds': instance.thresholds,
    };
