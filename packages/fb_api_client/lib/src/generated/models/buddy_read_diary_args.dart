// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_date_range.dart';

part 'buddy_read_diary_args.freezed.dart';
part 'buddy_read_diary_args.g.dart';

@Freezed()
abstract class BuddyReadDiaryArgs with _$BuddyReadDiaryArgs {
  const factory BuddyReadDiaryArgs({
    /// A day in the closed day grammar (as on intents), or null when range is set.
    required String? dateHint,
    required BuddyDateRange? range,
    required String? slotHint,
    required String? query,
  }) = _BuddyReadDiaryArgs;

  factory BuddyReadDiaryArgs.fromJson(Map<String, Object?> json) =>
      _$BuddyReadDiaryArgsFromJson(json);
}
