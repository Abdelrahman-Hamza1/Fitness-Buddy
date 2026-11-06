// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_body_measurement_kind.dart';
import 'buddy_import_metric.dart';
import 'buddy_import_row.dart';
import 'buddy_import_rows_kind.dart';
import 'buddy_intent.dart';

part 'buddy_import_rows.freezed.dart';
part 'buddy_import_rows.g.dart';

/// Pasted dated rows as read (B26, WB-030–032); the app infers units and flags problem rows in its review table.
@Freezed()
abstract class BuddyImportRows with _$BuddyImportRows {
  const factory BuddyImportRows({
    required BuddyImportRowsKind kind,
    required String language,
    required String script,
    required BuddyImportMetric metric,
    required BuddyBodyMeasurementKind? measurementKind,
    required List<BuddyImportRow> rows,
  }) = _BuddyImportRows;

  factory BuddyImportRows.fromJson(Map<String, Object?> json) =>
      _$BuddyImportRowsFromJson(json);
}
