// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_amount.dart';
import 'buddy_batch_kind.dart';
import 'buddy_batch_path.dart';
import 'buddy_food_item.dart';
import 'buddy_intent.dart';
import 'buddy_portion.dart';

part 'buddy_batch.freezed.dart';
part 'buddy_batch.g.dart';

/// A home-cooked batch (AI-100). The app owns the remaining-amount arithmetic.
@Freezed()
abstract class BuddyBatch with _$BuddyBatch {
  const factory BuddyBatch({
    required BuddyBatchKind kind,
    required String language,
    required String script,
    required String? name,

    /// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
    required List<BuddyFoodItem> ingredients,

    /// The cooked weight the user stated.
    required BuddyAmount? cookedWeight,
    required BuddyBatchPath? path,

    /// The portion eaten now (AI-101).
    required BuddyPortion? eatenNow,

    /// Literal time phrase as the user said it (B08); the app resolves it.
    required String? timeHint,

    /// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
    required String? slotHint,

    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,
  }) = _BuddyBatch;

  factory BuddyBatch.fromJson(Map<String, Object?> json) =>
      _$BuddyBatchFromJson(json);
}
