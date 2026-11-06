// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_energy_unit.dart';
import 'buddy_length_unit.dart';
import 'buddy_mass_unit.dart';

part 'buddy_units.freezed.dart';
part 'buddy_units.g.dart';

/// Display units for code-rendered claims. Energy is kcal only (LC-012).
@Freezed()
abstract class BuddyUnits with _$BuddyUnits {
  const factory BuddyUnits({
    required BuddyMassUnit mass,
    required BuddyLengthUnit length,
    required BuddyEnergyUnit energy,
  }) = _BuddyUnits;

  factory BuddyUnits.fromJson(Map<String, Object?> json) =>
      _$BuddyUnitsFromJson(json);
}
