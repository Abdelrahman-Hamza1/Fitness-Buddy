// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_unsupported_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyUnsupportedResult _$BuddyUnsupportedResultFromJson(
  Map<String, dynamic> json,
) => _BuddyUnsupportedResult(
  name: BuddyUnsupportedResultName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  ok: json['ok'] as bool,
  error: json['error'] == null
      ? null
      : BuddyPhoneToolError.fromJson(json['error'] as String),
);

Map<String, dynamic> _$BuddyUnsupportedResultToJson(
  _BuddyUnsupportedResult instance,
) => <String, dynamic>{
  'name': _$BuddyUnsupportedResultNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'ok': instance.ok,
  'error': _$BuddyPhoneToolErrorEnumMap[instance.error],
};

const _$BuddyUnsupportedResultNameEnumMap = {
  BuddyUnsupportedResultName.unsupported: 'unsupported',
  BuddyUnsupportedResultName.$unknown: r'$unknown',
};

const _$BuddyPhoneToolErrorEnumMap = {
  BuddyPhoneToolError.budgetExceeded: 'budgetExceeded',
  BuddyPhoneToolError.unsupportedPlan: 'unsupportedPlan',
  BuddyPhoneToolError.invalidArgs: 'invalidArgs',
  BuddyPhoneToolError.unavailable: 'unavailable',
  BuddyPhoneToolError.unsupported: 'unsupported',
  BuddyPhoneToolError.$unknown: r'$unknown',
};
