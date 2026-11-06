// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_phone_tools_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyPhoneToolsEvent _$BuddyPhoneToolsEventFromJson(
  Map<String, dynamic> json,
) => _BuddyPhoneToolsEvent(
  type: BuddyPhoneToolsEventType.fromJson(json['type'] as String),
  round: (json['round'] as num).toInt(),
  continuation: json['continuation'] as String,
  calls: (json['calls'] as List<dynamic>)
      .map((e) => BuddyPhoneToolCall.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddyPhoneToolsEventToJson(
  _BuddyPhoneToolsEvent instance,
) => <String, dynamic>{
  'type': _$BuddyPhoneToolsEventTypeEnumMap[instance.type]!,
  'round': instance.round,
  'continuation': instance.continuation,
  'calls': instance.calls.map((e) => e.toJson()).toList(),
};

const _$BuddyPhoneToolsEventTypeEnumMap = {
  BuddyPhoneToolsEventType.phoneTools: 'phoneTools',
  BuddyPhoneToolsEventType.$unknown: r'$unknown',
};
