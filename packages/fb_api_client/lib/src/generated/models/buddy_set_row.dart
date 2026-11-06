// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_set_row.freezed.dart';
part 'buddy_set_row.g.dart';

@Freezed()
abstract class BuddySetRow with _$BuddySetRow {
  const factory BuddySetRow({
    required int? reps,
    required double? kg,
    required int? durationSeconds,
    required double? distanceMeters,
  }) = _BuddySetRow;

  factory BuddySetRow.fromJson(Map<String, Object?> json) =>
      _$BuddySetRowFromJson(json);
}
