// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_error_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyErrorEvent _$BuddyErrorEventFromJson(Map<String, dynamic> json) =>
    _BuddyErrorEvent(
      type: BuddyErrorEventType.fromJson(json['type'] as String),
      code: BuddyTurnErrorCode.fromJson(json['code'] as String),
    );

Map<String, dynamic> _$BuddyErrorEventToJson(_BuddyErrorEvent instance) =>
    <String, dynamic>{
      'type': _$BuddyErrorEventTypeEnumMap[instance.type]!,
      'code': _$BuddyTurnErrorCodeEnumMap[instance.code]!,
    };

const _$BuddyErrorEventTypeEnumMap = {
  BuddyErrorEventType.error: 'error',
  BuddyErrorEventType.$unknown: r'$unknown',
};

const _$BuddyTurnErrorCodeEnumMap = {
  BuddyTurnErrorCode.unavailable: 'unavailable',
  BuddyTurnErrorCode.timeout: 'timeout',
  BuddyTurnErrorCode.invalid: 'invalid',
  BuddyTurnErrorCode.roundAlreadyRan: 'roundAlreadyRan',
  BuddyTurnErrorCode.expired: 'expired',
  BuddyTurnErrorCode.$unknown: r'$unknown',
};
