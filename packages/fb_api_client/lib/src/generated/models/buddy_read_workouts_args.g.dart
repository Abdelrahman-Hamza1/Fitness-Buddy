// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_workouts_args.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadWorkoutsArgs _$BuddyReadWorkoutsArgsFromJson(
  Map<String, dynamic> json,
) => _BuddyReadWorkoutsArgs(
  range: BuddyDateRange.fromJson(json['range'] as Map<String, dynamic>),
  exerciseRef: json['exerciseRef'] as String?,
);

Map<String, dynamic> _$BuddyReadWorkoutsArgsToJson(
  _BuddyReadWorkoutsArgs instance,
) => <String, dynamic>{
  'range': instance.range.toJson(),
  'exerciseRef': instance.exerciseRef,
};
