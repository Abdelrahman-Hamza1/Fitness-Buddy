// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_workout_session_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWorkoutSessionRow _$BuddyWorkoutSessionRowFromJson(
  Map<String, dynamic> json,
) => _BuddyWorkoutSessionRow(
  name: json['name'] as String?,
  id: json['id'] as String,
  date: json['date'] as String,
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => BuddyWorkoutExerciseRow.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddyWorkoutSessionRowToJson(
  _BuddyWorkoutSessionRow instance,
) => <String, dynamic>{
  'name': instance.name,
  'id': instance.id,
  'date': instance.date,
  'exercises': instance.exercises.map((e) => e.toJson()).toList(),
};
