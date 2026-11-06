// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_diary_row.freezed.dart';
part 'buddy_diary_row.g.dart';

@Freezed()
abstract class BuddyDiaryRow with _$BuddyDiaryRow {
  const factory BuddyDiaryRow({
    required String name,
    required String id,
    required String date,
    required String slot,
    required double? grams,
    required double? kcal,
  }) = _BuddyDiaryRow;

  factory BuddyDiaryRow.fromJson(Map<String, Object?> json) =>
      _$BuddyDiaryRowFromJson(json);
}
