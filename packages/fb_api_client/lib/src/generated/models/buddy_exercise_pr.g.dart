// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_exercise_pr.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyExercisePr _$BuddyExercisePrFromJson(Map<String, dynamic> json) =>
    _BuddyExercisePr(
      name: json['name'] as String,
      exerciseRef: json['exerciseRef'] as String,
      kg: (json['kg'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      date: json['date'] as String,
    );

Map<String, dynamic> _$BuddyExercisePrToJson(_BuddyExercisePr instance) =>
    <String, dynamic>{
      'name': instance.name,
      'exerciseRef': instance.exerciseRef,
      'kg': instance.kg,
      'reps': instance.reps,
      'date': instance.date,
    };
