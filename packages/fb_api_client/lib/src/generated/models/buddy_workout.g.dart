// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_workout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWorkout _$BuddyWorkoutFromJson(Map<String, dynamic> json) =>
    _BuddyWorkout(
      kind: BuddyWorkoutKind.fromJson(json['kind'] as String),
      name: json['name'] as String?,
      language: json['language'] as String,
      script: json['script'] as String,
      timeHint: json['timeHint'] as String?,
      dateHint: json['dateHint'] as String?,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => BuddyWorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyWorkoutToJson(_BuddyWorkout instance) =>
    <String, dynamic>{
      'kind': _$BuddyWorkoutKindEnumMap[instance.kind]!,
      'name': instance.name,
      'language': instance.language,
      'script': instance.script,
      'timeHint': instance.timeHint,
      'dateHint': instance.dateHint,
      'exercises': instance.exercises.map((e) => e.toJson()).toList(),
    };

const _$BuddyWorkoutKindEnumMap = {
  BuddyWorkoutKind.workout: 'workout',
  BuddyWorkoutKind.$unknown: r'$unknown',
};
