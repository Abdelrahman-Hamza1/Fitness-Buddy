// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_day_hint.freezed.dart';
part 'buddy_day_hint.g.dart';

@Freezed()
abstract class BuddyDayHint with _$BuddyDayHint {
  const factory BuddyDayHint({
    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,

    /// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
    required String? slotHint,

    /// Literal time phrase as the user said it (B08); the app resolves it.
    required String? timeHint,
  }) = _BuddyDayHint;

  factory BuddyDayHint.fromJson(Map<String, Object?> json) =>
      _$BuddyDayHintFromJson(json);
}
