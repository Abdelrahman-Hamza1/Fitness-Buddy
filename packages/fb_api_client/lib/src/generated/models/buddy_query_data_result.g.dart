// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_query_data_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyQueryDataResult _$BuddyQueryDataResultFromJson(
  Map<String, dynamic> json,
) => _BuddyQueryDataResult(
  name: BuddyQueryDataResultName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  ok: json['ok'] as bool,
  error: json['error'] == null
      ? null
      : BuddyPhoneToolError.fromJson(json['error'] as String),
  data: json['data'] == null
      ? null
      : BuddyQueryResultData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyQueryDataResultToJson(
  _BuddyQueryDataResult instance,
) => <String, dynamic>{
  'name': _$BuddyQueryDataResultNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'ok': instance.ok,
  'error': _$BuddyPhoneToolErrorEnumMap[instance.error],
  'data': instance.data?.toJson(),
};

const _$BuddyQueryDataResultNameEnumMap = {
  BuddyQueryDataResultName.queryData: 'queryData',
  BuddyQueryDataResultName.$unknown: r'$unknown',
};

const _$BuddyPhoneToolErrorEnumMap = {
  BuddyPhoneToolError.budgetExceeded: 'budgetExceeded',
  BuddyPhoneToolError.unsupportedPlan: 'unsupportedPlan',
  BuddyPhoneToolError.invalidArgs: 'invalidArgs',
  BuddyPhoneToolError.unavailable: 'unavailable',
  BuddyPhoneToolError.$unknown: r'$unknown',
};
