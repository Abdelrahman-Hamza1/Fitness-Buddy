// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_body_measurement_kind.dart';
import 'buddy_intent.dart';
import 'buddy_measurement_kind.dart';
import 'buddy_measurement_unit.dart';

part 'buddy_measurement.freezed.dart';
part 'buddy_measurement.g.dart';

/// A body measurement to log (B26). customTypeId is set exactly for kind custom.
@Freezed()
abstract class BuddyMeasurement with _$BuddyMeasurement {
  const factory BuddyMeasurement({
    required BuddyMeasurementKind kind,
    required String language,
    required String script,
    required BuddyBodyMeasurementKind measurementKind,
    required String? customTypeId,
    required double value,
    required BuddyMeasurementUnit unit,
    required String? timeHint,
    required String? dateHint,
  }) = _BuddyMeasurement;

  factory BuddyMeasurement.fromJson(Map<String, Object?> json) =>
      _$BuddyMeasurementFromJson(json);
}
