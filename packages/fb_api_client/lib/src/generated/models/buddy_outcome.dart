// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_outcome_status.dart';

part 'buddy_outcome.freezed.dart';
part 'buddy_outcome.g.dart';

/// What happened to one card of a history entry.
@Freezed()
abstract class BuddyOutcome with _$BuddyOutcome {
  const factory BuddyOutcome({
    /// The card's intent kind (open, ≤ 32).
    required String kind,
    required String proposalId,
    required BuddyOutcomeStatus status,

    /// The card's compact summary as the phone shows it.
    required String label,
  }) = _BuddyOutcome;

  factory BuddyOutcome.fromJson(Map<String, Object?> json) =>
      _$BuddyOutcomeFromJson(json);
}
