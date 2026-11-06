// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_habit_default.dart';
import 'buddy_memory.dart';
import 'buddy_ramadan.dart';
import 'buddy_units.dart';

part 'buddy_turn_profile.freezed.dart';
part 'buddy_turn_profile.g.dart';

@Freezed()
abstract class BuddyTurnProfile with _$BuddyTurnProfile {
  const factory BuddyTurnProfile({
    /// Up to 30 memory items (more via readMemory).
    required List<BuddyMemory> memory,

    /// Confirmed defaults and learned habits (weighing state, cooking fat, variants, portions), the same ones the ProposalEngine uses.
    required List<BuddyHabitDefault> defaults,
    required bool halal,
    required BuddyUnits units,
    required BuddyRamadan ramadan,
  }) = _BuddyTurnProfile;

  factory BuddyTurnProfile.fromJson(Map<String, Object?> json) =>
      _$BuddyTurnProfileFromJson(json);
}
