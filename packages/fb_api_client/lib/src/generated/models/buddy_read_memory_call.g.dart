// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_memory_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadMemoryCall _$BuddyReadMemoryCallFromJson(Map<String, dynamic> json) =>
    _BuddyReadMemoryCall(
      name: BuddyReadMemoryCallName.fromJson(json['name'] as String),
      callId: json['callId'] as String,
      args: BuddyReadMemoryArgs.fromJson(json['args'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyReadMemoryCallToJson(
  _BuddyReadMemoryCall instance,
) => <String, dynamic>{
  'name': _$BuddyReadMemoryCallNameEnumMap[instance.name]!,
  'callId': instance.callId,
  'args': instance.args.toJson(),
};

const _$BuddyReadMemoryCallNameEnumMap = {
  BuddyReadMemoryCallName.readMemory: 'readMemory',
  BuddyReadMemoryCallName.$unknown: r'$unknown',
};
