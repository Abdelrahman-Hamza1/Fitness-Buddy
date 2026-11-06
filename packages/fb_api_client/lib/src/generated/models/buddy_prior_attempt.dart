// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_prior_card.dart';

part 'buddy_prior_attempt.freezed.dart';
part 'buddy_prior_attempt.g.dart';

/// Retries only (06 §3.4): the failed attempt's cards. Confirmed and discarded ones are passed to the model as already handled, pending ones as still open.
@Freezed()
abstract class BuddyPriorAttempt with _$BuddyPriorAttempt {
  const factory BuddyPriorAttempt({
    required int attempt,
    required List<BuddyPriorCard> cards,
  }) = _BuddyPriorAttempt;

  factory BuddyPriorAttempt.fromJson(Map<String, Object?> json) =>
      _$BuddyPriorAttemptFromJson(json);
}
