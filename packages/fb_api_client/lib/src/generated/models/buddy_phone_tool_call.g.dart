// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_phone_tool_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuddyPhoneToolCallFindMyFoods _$BuddyPhoneToolCallFindMyFoodsFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolCallFindMyFoods(
  name: BuddyFindMyFoodsCallName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  args: BuddyFindMyFoodsArgs.fromJson(json['args'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyPhoneToolCallFindMyFoodsToJson(
  BuddyPhoneToolCallFindMyFoods instance,
) => <String, dynamic>{
  'name': _$BuddyFindMyFoodsCallNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'args': instance.args.toJson(),
};

const _$BuddyFindMyFoodsCallNameEnumMap = {
  BuddyFindMyFoodsCallName.findMyFoods: 'findMyFoods',
  BuddyFindMyFoodsCallName.$unknown: r'$unknown',
};

BuddyPhoneToolCallReadDiary _$BuddyPhoneToolCallReadDiaryFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolCallReadDiary(
  name: BuddyReadDiaryCallName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  args: BuddyReadDiaryArgs.fromJson(json['args'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyPhoneToolCallReadDiaryToJson(
  BuddyPhoneToolCallReadDiary instance,
) => <String, dynamic>{
  'name': _$BuddyReadDiaryCallNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'args': instance.args.toJson(),
};

const _$BuddyReadDiaryCallNameEnumMap = {
  BuddyReadDiaryCallName.readDiary: 'readDiary',
  BuddyReadDiaryCallName.$unknown: r'$unknown',
};

BuddyPhoneToolCallReadBody _$BuddyPhoneToolCallReadBodyFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolCallReadBody(
  name: BuddyReadBodyCallName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  args: BuddyReadBodyArgs.fromJson(json['args'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyPhoneToolCallReadBodyToJson(
  BuddyPhoneToolCallReadBody instance,
) => <String, dynamic>{
  'name': _$BuddyReadBodyCallNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'args': instance.args.toJson(),
};

const _$BuddyReadBodyCallNameEnumMap = {
  BuddyReadBodyCallName.readBody: 'readBody',
  BuddyReadBodyCallName.$unknown: r'$unknown',
};

BuddyPhoneToolCallReadWorkouts _$BuddyPhoneToolCallReadWorkoutsFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolCallReadWorkouts(
  name: BuddyReadWorkoutsCallName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  args: BuddyReadWorkoutsArgs.fromJson(json['args'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyPhoneToolCallReadWorkoutsToJson(
  BuddyPhoneToolCallReadWorkouts instance,
) => <String, dynamic>{
  'name': _$BuddyReadWorkoutsCallNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'args': instance.args.toJson(),
};

const _$BuddyReadWorkoutsCallNameEnumMap = {
  BuddyReadWorkoutsCallName.readWorkouts: 'readWorkouts',
  BuddyReadWorkoutsCallName.$unknown: r'$unknown',
};

BuddyPhoneToolCallReadMemory _$BuddyPhoneToolCallReadMemoryFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolCallReadMemory(
  name: BuddyReadMemoryCallName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  args: BuddyReadMemoryArgs.fromJson(json['args'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyPhoneToolCallReadMemoryToJson(
  BuddyPhoneToolCallReadMemory instance,
) => <String, dynamic>{
  'name': _$BuddyReadMemoryCallNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'args': instance.args.toJson(),
};

const _$BuddyReadMemoryCallNameEnumMap = {
  BuddyReadMemoryCallName.readMemory: 'readMemory',
  BuddyReadMemoryCallName.$unknown: r'$unknown',
};

BuddyPhoneToolCallQueryData _$BuddyPhoneToolCallQueryDataFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolCallQueryData(
  name: BuddyQueryDataCallName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  args: BuddyQueryPlan.fromJson(json['args'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyPhoneToolCallQueryDataToJson(
  BuddyPhoneToolCallQueryData instance,
) => <String, dynamic>{
  'name': _$BuddyQueryDataCallNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'args': instance.args.toJson(),
};

const _$BuddyQueryDataCallNameEnumMap = {
  BuddyQueryDataCallName.queryData: 'queryData',
  BuddyQueryDataCallName.$unknown: r'$unknown',
};

BuddyPhoneToolCallUnrecognized _$BuddyPhoneToolCallUnrecognizedFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolCallUnrecognized($type: json['name'] as String?);

Map<String, dynamic> _$BuddyPhoneToolCallUnrecognizedToJson(
  BuddyPhoneToolCallUnrecognized instance,
) => <String, dynamic>{'name': instance.$type};
