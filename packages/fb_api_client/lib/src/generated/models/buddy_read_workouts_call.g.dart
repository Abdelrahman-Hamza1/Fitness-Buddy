// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_workouts_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadWorkoutsCall _$BuddyReadWorkoutsCallFromJson(
  Map<String, dynamic> json,
) => _BuddyReadWorkoutsCall(
  name: BuddyReadWorkoutsCallName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  args: BuddyReadWorkoutsArgs.fromJson(json['args'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyReadWorkoutsCallToJson(
  _BuddyReadWorkoutsCall instance,
) => <String, dynamic>{
  'name': _$BuddyReadWorkoutsCallNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'args': instance.args.toJson(),
};

const _$BuddyReadWorkoutsCallNameEnumMap = {
  BuddyReadWorkoutsCallName.readWorkouts: 'readWorkouts',
  BuddyReadWorkoutsCallName.$unknown: r'$unknown',
};
