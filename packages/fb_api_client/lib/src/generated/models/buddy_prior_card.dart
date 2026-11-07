// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_prior_card_status.dart';

part 'buddy_prior_card.freezed.dart';
part 'buddy_prior_card.g.dart';

@Freezed()
abstract class BuddyPriorCard with _$BuddyPriorCard {
  const factory BuddyPriorCard({
    required String proposalId,
    required BuddyPriorCardStatus status,

    /// The card's current revision on the phone; a retry's update names it in replaces.expectedRevision.
    required int revision,

    /// The card's compact summary.
    required String line,
  }) = _BuddyPriorCard;

  factory BuddyPriorCard.fromJson(Map<String, Object?> json) =>
      _$BuddyPriorCardFromJson(json);
}
