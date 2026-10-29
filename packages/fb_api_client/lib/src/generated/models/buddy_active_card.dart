// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_active_card_line.dart';

part 'buddy_active_card.freezed.dart';
part 'buddy_active_card.g.dart';

/// Bounded summary of the open proposal card: names and amounts only, no IDs, no nutrients.
@Freezed()
abstract class BuddyActiveCard with _$BuddyActiveCard {
  const factory BuddyActiveCard({
    /// The card's slot name.
    required String? slot,

    /// The card's local time, HH:mm.
    required String? time,

    /// At most 30 lines.
    required List<BuddyActiveCardLine> lines,
  }) = _BuddyActiveCard;

  factory BuddyActiveCard.fromJson(Map<String, Object?> json) =>
      _$BuddyActiveCardFromJson(json);
}
