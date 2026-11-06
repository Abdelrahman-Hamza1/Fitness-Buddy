// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_day_totals.dart';
import 'buddy_open_card.dart';
import 'buddy_slot.dart';

part 'buddy_turn_snapshot.freezed.dart';
part 'buddy_turn_snapshot.g.dart';

@Freezed()
abstract class BuddyTurnSnapshot with _$BuddyTurnSnapshot {
  const factory BuddyTurnSnapshot({
    required DateTime now,
    required int tzOffsetMin,
    required List<BuddySlot> slots,
    required BuddyDayTotals today,

    /// Up to 5 still-pending cards a follow-up may update with replaces.
    required List<BuddyOpenCard> openCards,
  }) = _BuddyTurnSnapshot;

  factory BuddyTurnSnapshot.fromJson(Map<String, Object?> json) =>
      _$BuddyTurnSnapshotFromJson(json);
}
