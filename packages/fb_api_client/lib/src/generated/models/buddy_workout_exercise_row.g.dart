// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_workout_exercise_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWorkoutExerciseRow _$BuddyWorkoutExerciseRowFromJson(
  Map<String, dynamic> json,
) => _BuddyWorkoutExerciseRow(
  name: json['name'] as String,
  exerciseRef: json['exerciseRef'] as String,
  sets: (json['sets'] as List<dynamic>)
      .map((e) => BuddySetRow.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddyWorkoutExerciseRowToJson(
  _BuddyWorkoutExerciseRow instance,
) => <String, dynamic>{
  'name': instance.name,
  'exerciseRef': instance.exerciseRef,
  'sets': instance.sets.map((e) => e.toJson()).toList(),
};
