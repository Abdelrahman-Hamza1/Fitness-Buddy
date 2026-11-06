// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_set_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddySetRow _$BuddySetRowFromJson(Map<String, dynamic> json) => _BuddySetRow(
  reps: (json['reps'] as num?)?.toInt(),
  kg: (json['kg'] as num?)?.toDouble(),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
);

Map<String, dynamic> _$BuddySetRowToJson(_BuddySetRow instance) =>
    <String, dynamic>{
      'reps': instance.reps,
      'kg': instance.kg,
      'durationSeconds': instance.durationSeconds,
      'distanceMeters': instance.distanceMeters,
    };
