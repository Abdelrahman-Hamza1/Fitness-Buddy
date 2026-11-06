// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_workout_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWorkoutExercise _$BuddyWorkoutExerciseFromJson(
  Map<String, dynamic> json,
) => _BuddyWorkoutExercise(
  mention: json['mention'] as String,
  exerciseRef: json['exerciseRef'] as String?,
  sets: (json['sets'] as List<dynamic>)
      .map((e) => BuddyWorkoutSet.fromJson(e as Map<String, dynamic>))
      .toList(),
  assumptions: (json['assumptions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$BuddyWorkoutExerciseToJson(
  _BuddyWorkoutExercise instance,
) => <String, dynamic>{
  'mention': instance.mention,
  'exerciseRef': instance.exerciseRef,
  'sets': instance.sets.map((e) => e.toJson()).toList(),
  'assumptions': instance.assumptions,
};
