// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_measurement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyMeasurement _$BuddyMeasurementFromJson(Map<String, dynamic> json) =>
    _BuddyMeasurement(
      kind: BuddyMeasurementKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      measurementKind: BuddyBodyMeasurementKind.fromJson(
        json['measurementKind'] as String,
      ),
      customTypeId: json['customTypeId'] as String?,
      value: (json['value'] as num).toDouble(),
      unit: BuddyMeasurementUnit.fromJson(json['unit'] as String),
      timeHint: json['timeHint'] as String?,
      dateHint: json['dateHint'] as String?,
    );

Map<String, dynamic> _$BuddyMeasurementToJson(_BuddyMeasurement instance) =>
    <String, dynamic>{
      'kind': _$BuddyMeasurementKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'measurementKind':
          _$BuddyBodyMeasurementKindEnumMap[instance.measurementKind]!,
      'customTypeId': instance.customTypeId,
      'value': instance.value,
      'unit': _$BuddyMeasurementUnitEnumMap[instance.unit]!,
      'timeHint': instance.timeHint,
      'dateHint': instance.dateHint,
    };

const _$BuddyMeasurementKindEnumMap = {
  BuddyMeasurementKind.measurement: 'measurement',
  BuddyMeasurementKind.$unknown: r'$unknown',
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

const _$BuddyMeasurementUnitEnumMap = {
  BuddyMeasurementUnit.cm: 'cm',
  BuddyMeasurementUnit.valueIn: 'in',
  BuddyMeasurementUnit.percent: 'percent',
  BuddyMeasurementUnit.$unknown: r'$unknown',
};
