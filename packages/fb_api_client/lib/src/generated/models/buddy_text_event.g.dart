// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_text_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyTextEvent _$BuddyTextEventFromJson(Map<String, dynamic> json) =>
    _BuddyTextEvent(
      type: BuddyTextEventType.fromJson(json['type'] as String),
      text: json['text'] as String,
    );

Map<String, dynamic> _$BuddyTextEventToJson(_BuddyTextEvent instance) =>
    <String, dynamic>{
      'type': _$BuddyTextEventTypeEnumMap[instance.type]!,
      'text': instance.text,
    };

const _$BuddyTextEventTypeEnumMap = {
  BuddyTextEventType.text: 'text',
  BuddyTextEventType.$unknown: r'$unknown',
};
