// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_phone_tool_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuddyPhoneToolResultFindMyFoods _$BuddyPhoneToolResultFindMyFoodsFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolResultFindMyFoods(
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

Map<String, dynamic> _$BuddyPhoneToolResultFindMyFoodsToJson(
  BuddyPhoneToolResultFindMyFoods instance,
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

BuddyPhoneToolResultReadDiary _$BuddyPhoneToolResultReadDiaryFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolResultReadDiary(
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

Map<String, dynamic> _$BuddyPhoneToolResultReadDiaryToJson(
  BuddyPhoneToolResultReadDiary instance,
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

BuddyPhoneToolResultReadBody _$BuddyPhoneToolResultReadBodyFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolResultReadBody(
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

Map<String, dynamic> _$BuddyPhoneToolResultReadBodyToJson(
  BuddyPhoneToolResultReadBody instance,
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

BuddyPhoneToolResultReadWorkouts _$BuddyPhoneToolResultReadWorkoutsFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolResultReadWorkouts(
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

Map<String, dynamic> _$BuddyPhoneToolResultReadWorkoutsToJson(
  BuddyPhoneToolResultReadWorkouts instance,
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

BuddyPhoneToolResultReadMemory _$BuddyPhoneToolResultReadMemoryFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolResultReadMemory(
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

Map<String, dynamic> _$BuddyPhoneToolResultReadMemoryToJson(
  BuddyPhoneToolResultReadMemory instance,
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

BuddyPhoneToolResultQueryData _$BuddyPhoneToolResultQueryDataFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolResultQueryData(
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

Map<String, dynamic> _$BuddyPhoneToolResultQueryDataToJson(
  BuddyPhoneToolResultQueryData instance,
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

BuddyPhoneToolResultUnsupported _$BuddyPhoneToolResultUnsupportedFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolResultUnsupported(
  name: BuddyUnsupportedResultName.fromJson(json['name'] as String),
  callId: json['callId'] as String,
  ok: json['ok'] as bool,
  error: json['error'] == null
      ? null
      : BuddyPhoneToolError.fromJson(json['error'] as String),
);

Map<String, dynamic> _$BuddyPhoneToolResultUnsupportedToJson(
  BuddyPhoneToolResultUnsupported instance,
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

BuddyPhoneToolResultUnrecognized _$BuddyPhoneToolResultUnrecognizedFromJson(
  Map<String, dynamic> json,
) => BuddyPhoneToolResultUnrecognized($type: json['name'] as String?);

Map<String, dynamic> _$BuddyPhoneToolResultUnrecognizedToJson(
  BuddyPhoneToolResultUnrecognized instance,
) => <String, dynamic>{'name': instance.$type};
