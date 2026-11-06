// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_memory_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadMemoryResult _$BuddyReadMemoryResultFromJson(
  Map<String, dynamic> json,
) => _BuddyReadMemoryResult(
  name: BuddyReadMemoryResultName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  ok: json['ok'] as bool,
  error: json['error'] == null
      ? null
      : BuddyPhoneToolError.fromJson(json['error'] as String),
  data: json['data'] == null
      ? null
      : BuddyReadMemoryData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyReadMemoryResultToJson(
  _BuddyReadMemoryResult instance,
) => <String, dynamic>{
  'name': _$BuddyReadMemoryResultNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'ok': instance.ok,
  'error': _$BuddyPhoneToolErrorEnumMap[instance.error],
  'data': instance.data?.toJson(),
};

const _$BuddyReadMemoryResultNameEnumMap = {
  BuddyReadMemoryResultName.readMemory: 'readMemory',
  BuddyReadMemoryResultName.$unknown: r'$unknown',
};

const _$BuddyPhoneToolErrorEnumMap = {
  BuddyPhoneToolError.budgetExceeded: 'budgetExceeded',
  BuddyPhoneToolError.unsupportedPlan: 'unsupportedPlan',
  BuddyPhoneToolError.invalidArgs: 'invalidArgs',
  BuddyPhoneToolError.unavailable: 'unavailable',
  BuddyPhoneToolError.$unknown: r'$unknown',
};
