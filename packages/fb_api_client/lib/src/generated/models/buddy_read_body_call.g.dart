// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_body_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadBodyCall _$BuddyReadBodyCallFromJson(Map<String, dynamic> json) =>
    _BuddyReadBodyCall(
      name: BuddyReadBodyCallName.fromJson(json['name'] as String),
      callId: json['callId'] as String,
      args: BuddyReadBodyArgs.fromJson(json['args'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyReadBodyCallToJson(_BuddyReadBodyCall instance) =>
    <String, dynamic>{
      'name': _$BuddyReadBodyCallNameEnumMap[instance.name]!,
      'callId': instance.callId,
      'args': instance.args.toJson(),
    };

const _$BuddyReadBodyCallNameEnumMap = {
  BuddyReadBodyCallName.readBody: 'readBody',
  BuddyReadBodyCallName.$unknown: r'$unknown',
};
