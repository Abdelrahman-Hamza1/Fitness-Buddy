// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_workout_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWorkoutSet _$BuddyWorkoutSetFromJson(Map<String, dynamic> json) =>
    _BuddyWorkoutSet(
      reps: (json['reps'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      unit: json['unit'] == null
          ? null
          : BuddyLoadUnit.fromJson(json['unit'] as String),
      perDumbbell: json['perDumbbell'] as bool,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BuddyWorkoutSetToJson(_BuddyWorkoutSet instance) =>
    <String, dynamic>{
      'reps': instance.reps,
      'weight': instance.weight,
      'unit': _$BuddyLoadUnitEnumMap[instance.unit],
      'perDumbbell': instance.perDumbbell,
      'durationSeconds': instance.durationSeconds,
      'distanceMeters': instance.distanceMeters,
    };

const _$BuddyLoadUnitEnumMap = {
  BuddyLoadUnit.kg: 'kg',
  BuddyLoadUnit.lb: 'lb',
  BuddyLoadUnit.$unknown: r'$unknown',
};
