// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_body_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadBodyResult _$BuddyReadBodyResultFromJson(Map<String, dynamic> json) =>
    _BuddyReadBodyResult(
      name: BuddyReadBodyResultName.fromJson(json['name'] as String),
      callId: json['callId'] as String,
      ok: json['ok'] as bool,
      error: json['error'] == null
          ? null
          : BuddyPhoneToolError.fromJson(json['error'] as String),
      data: json['data'] == null
          ? null
          : BuddyReadBodyData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyReadBodyResultToJson(
  _BuddyReadBodyResult instance,
) => <String, dynamic>{
  'name': _$BuddyReadBodyResultNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'ok': instance.ok,
  'error': _$BuddyPhoneToolErrorEnumMap[instance.error],
  'data': instance.data?.toJson(),
};

const _$BuddyReadBodyResultNameEnumMap = {
  BuddyReadBodyResultName.readBody: 'readBody',
  BuddyReadBodyResultName.$unknown: r'$unknown',
};

const _$BuddyPhoneToolErrorEnumMap = {
  BuddyPhoneToolError.budgetExceeded: 'budgetExceeded',
  BuddyPhoneToolError.unsupportedPlan: 'unsupportedPlan',
  BuddyPhoneToolError.invalidArgs: 'invalidArgs',
  BuddyPhoneToolError.unavailable: 'unavailable',
  BuddyPhoneToolError.unsupported: 'unsupported',
  BuddyPhoneToolError.$unknown: r'$unknown',
};
