// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_weekly_workouts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWeeklyWorkouts _$BuddyWeeklyWorkoutsFromJson(Map<String, dynamic> json) =>
    _BuddyWeeklyWorkouts(
      sessions: (json['sessions'] as num).toInt(),
      planned: (json['planned'] as num?)?.toInt(),
      prs: (json['prs'] as num).toInt(),
    );

Map<String, dynamic> _$BuddyWeeklyWorkoutsToJson(
  _BuddyWeeklyWorkouts instance,
) => <String, dynamic>{
  'sessions': instance.sessions,
  'planned': instance.planned,
  'prs': instance.prs,
};
