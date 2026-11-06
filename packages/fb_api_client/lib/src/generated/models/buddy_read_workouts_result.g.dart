// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_workouts_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadWorkoutsResult _$BuddyReadWorkoutsResultFromJson(
  Map<String, dynamic> json,
) => _BuddyReadWorkoutsResult(
  name: BuddyReadWorkoutsResultName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  ok: json['ok'] as bool,
  error: json['error'] == null
      ? null
      : BuddyPhoneToolError.fromJson(json['error'] as String),
  data: json['data'] == null
      ? null
      : BuddyReadWorkoutsData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyReadWorkoutsResultToJson(
  _BuddyReadWorkoutsResult instance,
) => <String, dynamic>{
  'name': _$BuddyReadWorkoutsResultNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'ok': instance.ok,
  'error': _$BuddyPhoneToolErrorEnumMap[instance.error],
  'data': instance.data?.toJson(),
};

const _$BuddyReadWorkoutsResultNameEnumMap = {
  BuddyReadWorkoutsResultName.readWorkouts: 'readWorkouts',
  BuddyReadWorkoutsResultName.$unknown: r'$unknown',
};

const _$BuddyPhoneToolErrorEnumMap = {
  BuddyPhoneToolError.budgetExceeded: 'budgetExceeded',
  BuddyPhoneToolError.unsupportedPlan: 'unsupportedPlan',
  BuddyPhoneToolError.invalidArgs: 'invalidArgs',
  BuddyPhoneToolError.unavailable: 'unavailable',
  BuddyPhoneToolError.$unknown: r'$unknown',
};
