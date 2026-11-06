// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_units.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyUnits _$BuddyUnitsFromJson(Map<String, dynamic> json) => _BuddyUnits(
  mass: BuddyMassUnit.fromJson(json['mass'] as String),
  length: BuddyLengthUnit.fromJson(json['length'] as String),
  energy: BuddyEnergyUnit.fromJson(json['energy'] as String),
);

Map<String, dynamic> _$BuddyUnitsToJson(_BuddyUnits instance) =>
    <String, dynamic>{
      'mass': _$BuddyMassUnitEnumMap[instance.mass]!,
      'length': _$BuddyLengthUnitEnumMap[instance.length]!,
      'energy': _$BuddyEnergyUnitEnumMap[instance.energy]!,
    };

const _$BuddyMassUnitEnumMap = {
  BuddyMassUnit.kg: 'kg',
  BuddyMassUnit.lb: 'lb',
  BuddyMassUnit.$unknown: r'$unknown',
};

const _$BuddyLengthUnitEnumMap = {
  BuddyLengthUnit.cm: 'cm',
  BuddyLengthUnit.valueIn: 'in',
  BuddyLengthUnit.$unknown: r'$unknown',
};

const _$BuddyEnergyUnitEnumMap = {
  BuddyEnergyUnit.kcal: 'kcal',
  BuddyEnergyUnit.$unknown: r'$unknown',
};
