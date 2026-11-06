// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_done_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDoneEvent _$BuddyDoneEventFromJson(Map<String, dynamic> json) =>
    _BuddyDoneEvent(
      type: BuddyDoneEventType.fromJson(json['type'] as String),
      reason: BuddyDoneReason.fromJson(json['reason'] as String),
      usage: BuddyTurnUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyDoneEventToJson(_BuddyDoneEvent instance) =>
    <String, dynamic>{
      'type': _$BuddyDoneEventTypeEnumMap[instance.type]!,
      'reason': _$BuddyDoneReasonEnumMap[instance.reason]!,
      'usage': instance.usage.toJson(),
    };

const _$BuddyDoneEventTypeEnumMap = {
  BuddyDoneEventType.done: 'done',
  BuddyDoneEventType.$unknown: r'$unknown',
};

const _$BuddyDoneReasonEnumMap = {
  BuddyDoneReason.answered: 'answered',
  BuddyDoneReason.asked: 'asked',
  BuddyDoneReason.declined: 'declined',
  BuddyDoneReason.limit: 'limit',
  BuddyDoneReason.quota: 'quota',
  BuddyDoneReason.$unknown: r'$unknown',
};
