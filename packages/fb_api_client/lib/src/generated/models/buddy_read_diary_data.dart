// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_diary_row.dart';

part 'buddy_read_diary_data.freezed.dart';
part 'buddy_read_diary_data.g.dart';

@Freezed()
abstract class BuddyReadDiaryData with _$BuddyReadDiaryData {
  const factory BuddyReadDiaryData({
    required List<BuddyDiaryRow> entries,

    /// True when the scope cut the rows.
    required bool truncated,
  }) = _BuddyReadDiaryData;

  factory BuddyReadDiaryData.fromJson(Map<String, Object?> json) =>
      _$BuddyReadDiaryDataFromJson(json);
}
