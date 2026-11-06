// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_import_row.freezed.dart';
part 'buddy_import_row.g.dart';

@Freezed()
abstract class BuddyImportRow with _$BuddyImportRow {
  const factory BuddyImportRow({
    required String? date,
    required double? value,

    /// The unit as written, or null ("110k" keeps "k").
    required String? unit,
    required String original,
  }) = _BuddyImportRow;

  factory BuddyImportRow.fromJson(Map<String, Object?> json) =>
      _$BuddyImportRowFromJson(json);
}
