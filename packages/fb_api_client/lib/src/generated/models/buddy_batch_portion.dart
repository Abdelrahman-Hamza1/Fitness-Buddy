// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_batch_portion_kind.dart';
import 'buddy_intent.dart';
import 'buddy_portion.dart';

part 'buddy_batch_portion.freezed.dart';
part 'buddy_batch_portion.g.dart';

/// A portion of an open batch (AI-102). Exactly one of a non-null portion or rest true.
@Freezed()
abstract class BuddyBatchPortion with _$BuddyBatchPortion {
  const factory BuddyBatchPortion({
    required BuddyBatchPortionKind kind,
    required String language,
    required String script,

    /// A request openBatches ID.
    required String batchId,

    /// The portion eaten; null when rest is true.
    required BuddyPortion? portion,

    /// The user ate the rest of the batch.
    required bool rest,

    /// Literal time phrase as the user said it (B08); the app resolves it.
    required String? timeHint,

    /// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
    required String? slotHint,

    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,
  }) = _BuddyBatchPortion;

  factory BuddyBatchPortion.fromJson(Map<String, Object?> json) =>
      _$BuddyBatchPortionFromJson(json);
}
