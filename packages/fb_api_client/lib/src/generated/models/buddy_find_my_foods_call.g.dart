// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_find_my_foods_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyFindMyFoodsCall _$BuddyFindMyFoodsCallFromJson(
  Map<String, dynamic> json,
) => _BuddyFindMyFoodsCall(
  name: BuddyFindMyFoodsCallName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  args: BuddyFindMyFoodsArgs.fromJson(json['args'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyFindMyFoodsCallToJson(
  _BuddyFindMyFoodsCall instance,
) => <String, dynamic>{
  'name': _$BuddyFindMyFoodsCallNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'args': instance.args.toJson(),
};

const _$BuddyFindMyFoodsCallNameEnumMap = {
  BuddyFindMyFoodsCallName.findMyFoods: 'findMyFoods',
  BuddyFindMyFoodsCallName.$unknown: r'$unknown',
};
