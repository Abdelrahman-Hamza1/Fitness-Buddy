// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_import_rows.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyImportRows _$BuddyImportRowsFromJson(Map<String, dynamic> json) =>
    _BuddyImportRows(
      kind: BuddyImportRowsKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      metric: BuddyImportMetric.fromJson(json['metric'] as String),
      measurementKind: json['measurementKind'] == null
          ? null
          : BuddyBodyMeasurementKind.fromJson(
              json['measurementKind'] as String,
            ),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => BuddyImportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyImportRowsToJson(_BuddyImportRows instance) =>
    <String, dynamic>{
      'kind': _$BuddyImportRowsKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'metric': _$BuddyImportMetricEnumMap[instance.metric]!,
      'measurementKind':
          _$BuddyBodyMeasurementKindEnumMap[instance.measurementKind],
      'rows': instance.rows.map((e) => e.toJson()).toList(),
    };

const _$BuddyImportRowsKindEnumMap = {
  BuddyImportRowsKind.importRows: 'importRows',
  BuddyImportRowsKind.$unknown: r'$unknown',
};

const _$BuddyImportMetricEnumMap = {
  BuddyImportMetric.weight: 'weight',
  BuddyImportMetric.measurement: 'measurement',
  BuddyImportMetric.$unknown: r'$unknown',
};

const _$BuddyBodyMeasurementKindEnumMap = {
  BuddyBodyMeasurementKind.waist: 'waist',
  BuddyBodyMeasurementKind.chest: 'chest',
  BuddyBodyMeasurementKind.hips: 'hips',
  BuddyBodyMeasurementKind.arm: 'arm',
  BuddyBodyMeasurementKind.thigh: 'thigh',
  BuddyBodyMeasurementKind.neck: 'neck',
  BuddyBodyMeasurementKind.bodyFat: 'bodyFat',
  BuddyBodyMeasurementKind.custom: 'custom',
  BuddyBodyMeasurementKind.$unknown: r'$unknown',
};
