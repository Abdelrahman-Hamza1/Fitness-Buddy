// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_workouts_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadWorkoutsData _$BuddyReadWorkoutsDataFromJson(
  Map<String, dynamic> json,
) => _BuddyReadWorkoutsData(
  sessions: (json['sessions'] as List<dynamic>)
      .map((e) => BuddyWorkoutSessionRow.fromJson(e as Map<String, dynamic>))
      .toList(),
  prs: (json['prs'] as List<dynamic>)
      .map((e) => BuddyExercisePr.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddyReadWorkoutsDataToJson(
  _BuddyReadWorkoutsData instance,
) => <String, dynamic>{
  'sessions': instance.sessions.map((e) => e.toJson()).toList(),
  'prs': instance.prs.map((e) => e.toJson()).toList(),
};
