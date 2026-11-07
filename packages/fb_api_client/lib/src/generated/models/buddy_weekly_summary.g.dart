// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_weekly_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWeeklySummary _$BuddyWeeklySummaryFromJson(
  Map<String, dynamic> json,
) => _BuddyWeeklySummary(
  start: json['start'] as String,
  end: json['end'] as String,
  elapsedDays: (json['elapsedDays'] as num).toInt(),
  countedDays: (json['countedDays'] as num).toInt(),
  targetDays: (json['targetDays'] as num).toInt(),
  daysWithinTarget: (json['daysWithinTarget'] as num).toInt(),
  proteinTargetDays: (json['proteinTargetDays'] as num).toInt(),
  proteinDaysHit: (json['proteinDaysHit'] as num).toInt(),
  averageKcal: (json['averageKcal'] as num?)?.toDouble(),
  averageTargetKcal: (json['averageTargetKcal'] as num?)?.toDouble(),
  averageFiberG: (json['averageFiberG'] as num?)?.toDouble(),
  trendChangeKg: (json['trendChangeKg'] as num?)?.toDouble(),
  workouts: json['workouts'] == null
      ? null
      : BuddyWeeklyWorkouts.fromJson(json['workouts'] as Map<String, dynamic>),
  estimated: json['estimated'] as bool,
  checkIn: json['checkIn'] == null
      ? null
      : BuddyWeeklyCheckIn.fromJson(json['checkIn'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyWeeklySummaryToJson(_BuddyWeeklySummary instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'elapsedDays': instance.elapsedDays,
      'countedDays': instance.countedDays,
      'targetDays': instance.targetDays,
      'daysWithinTarget': instance.daysWithinTarget,
      'proteinTargetDays': instance.proteinTargetDays,
      'proteinDaysHit': instance.proteinDaysHit,
      'averageKcal': instance.averageKcal,
      'averageTargetKcal': instance.averageTargetKcal,
      'averageFiberG': instance.averageFiberG,
      'trendChangeKg': instance.trendChangeKg,
      'workouts': instance.workouts?.toJson(),
      'estimated': instance.estimated,
      'checkIn': instance.checkIn?.toJson(),
    };
