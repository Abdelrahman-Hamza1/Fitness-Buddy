// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_diary_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadDiaryCall _$BuddyReadDiaryCallFromJson(Map<String, dynamic> json) =>
    _BuddyReadDiaryCall(
      name: BuddyReadDiaryCallName.fromJson(json['name'] as String),
      callId: json['callId'] as String,
      args: BuddyReadDiaryArgs.fromJson(json['args'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyReadDiaryCallToJson(_BuddyReadDiaryCall instance) =>
    <String, dynamic>{
      'name': _$BuddyReadDiaryCallNameEnumMap[instance.name]!,
      'callId': instance.callId,
      'args': instance.args.toJson(),
    };

const _$BuddyReadDiaryCallNameEnumMap = {
  BuddyReadDiaryCallName.readDiary: 'readDiary',
  BuddyReadDiaryCallName.$unknown: r'$unknown',
};
