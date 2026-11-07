// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_diary_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadDiaryResult _$BuddyReadDiaryResultFromJson(
  Map<String, dynamic> json,
) => _BuddyReadDiaryResult(
  name: BuddyReadDiaryResultName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  ok: json['ok'] as bool,
  error: json['error'] == null
      ? null
      : BuddyPhoneToolError.fromJson(json['error'] as String),
  data: json['data'] == null
      ? null
      : BuddyReadDiaryData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyReadDiaryResultToJson(
  _BuddyReadDiaryResult instance,
) => <String, dynamic>{
  'name': _$BuddyReadDiaryResultNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'ok': instance.ok,
  'error': _$BuddyPhoneToolErrorEnumMap[instance.error],
  'data': instance.data?.toJson(),
};

const _$BuddyReadDiaryResultNameEnumMap = {
  BuddyReadDiaryResultName.readDiary: 'readDiary',
  BuddyReadDiaryResultName.$unknown: r'$unknown',
};

const _$BuddyPhoneToolErrorEnumMap = {
  BuddyPhoneToolError.budgetExceeded: 'budgetExceeded',
  BuddyPhoneToolError.unsupportedPlan: 'unsupportedPlan',
  BuddyPhoneToolError.invalidArgs: 'invalidArgs',
  BuddyPhoneToolError.unavailable: 'unavailable',
  BuddyPhoneToolError.unsupported: 'unsupported',
  BuddyPhoneToolError.$unknown: r'$unknown',
};
