// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_turn_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyTurnProfile _$BuddyTurnProfileFromJson(Map<String, dynamic> json) =>
    _BuddyTurnProfile(
      memory: (json['memory'] as List<dynamic>)
          .map((e) => BuddyMemory.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaults: (json['defaults'] as List<dynamic>)
          .map((e) => BuddyHabitDefault.fromJson(e as Map<String, dynamic>))
          .toList(),
      halal: json['halal'] as bool,
      units: BuddyUnits.fromJson(json['units'] as Map<String, dynamic>),
      ramadan: BuddyRamadan.fromJson(json['ramadan'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyTurnProfileToJson(_BuddyTurnProfile instance) =>
    <String, dynamic>{
      'memory': instance.memory.map((e) => e.toJson()).toList(),
      'defaults': instance.defaults.map((e) => e.toJson()).toList(),
      'halal': instance.halal,
      'units': instance.units.toJson(),
      'ramadan': instance.ramadan.toJson(),
    };
