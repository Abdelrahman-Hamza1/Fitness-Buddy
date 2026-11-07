// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_find_my_foods_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyFindMyFoodsResult _$BuddyFindMyFoodsResultFromJson(
  Map<String, dynamic> json,
) => _BuddyFindMyFoodsResult(
  name: BuddyFindMyFoodsResultName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  ok: json['ok'] as bool,
  error: json['error'] == null
      ? null
      : BuddyPhoneToolError.fromJson(json['error'] as String),
  data: json['data'] == null
      ? null
      : BuddyFindMyFoodsData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyFindMyFoodsResultToJson(
  _BuddyFindMyFoodsResult instance,
) => <String, dynamic>{
  'name': _$BuddyFindMyFoodsResultNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'ok': instance.ok,
  'error': _$BuddyPhoneToolErrorEnumMap[instance.error],
  'data': instance.data?.toJson(),
};

const _$BuddyFindMyFoodsResultNameEnumMap = {
  BuddyFindMyFoodsResultName.findMyFoods: 'findMyFoods',
  BuddyFindMyFoodsResultName.$unknown: r'$unknown',
};

const _$BuddyPhoneToolErrorEnumMap = {
  BuddyPhoneToolError.budgetExceeded: 'budgetExceeded',
  BuddyPhoneToolError.unsupportedPlan: 'unsupportedPlan',
  BuddyPhoneToolError.invalidArgs: 'invalidArgs',
  BuddyPhoneToolError.unavailable: 'unavailable',
  BuddyPhoneToolError.unsupported: 'unsupported',
  BuddyPhoneToolError.$unknown: r'$unknown',
};
