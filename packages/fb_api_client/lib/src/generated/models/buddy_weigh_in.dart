// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_intent.dart';
import 'buddy_weigh_in_kind.dart';

part 'buddy_weigh_in.freezed.dart';
part 'buddy_weigh_in.g.dart';

@Freezed()
abstract class BuddyWeighIn with _$BuddyWeighIn {
  const factory BuddyWeighIn({
    required BuddyWeighInKind kind,
    required String language,
    required String script,
    required double value,
    required String unit,

    /// Literal time phrase as the user said it (B08); the app resolves it.
    required String? timeHint,

    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,
  }) = _BuddyWeighIn;

  factory BuddyWeighIn.fromJson(Map<String, Object?> json) =>
      _$BuddyWeighInFromJson(json);
}
