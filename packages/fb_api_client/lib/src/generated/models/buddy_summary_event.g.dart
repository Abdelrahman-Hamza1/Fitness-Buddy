// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_summary_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddySummaryEvent _$BuddySummaryEventFromJson(Map<String, dynamic> json) =>
    _BuddySummaryEvent(
      type: BuddySummaryEventType.fromJson(json['type'] as String),
      text: json['text'] as String,
      revision: (json['revision'] as num).toInt(),
      watermark: json['watermark'] as String,
    );

Map<String, dynamic> _$BuddySummaryEventToJson(_BuddySummaryEvent instance) =>
    <String, dynamic>{
      'type': _$BuddySummaryEventTypeEnumMap[instance.type]!,
      'text': instance.text,
      'revision': instance.revision,
      'watermark': instance.watermark,
    };

const _$BuddySummaryEventTypeEnumMap = {
  BuddySummaryEventType.summary: 'summary',
  BuddySummaryEventType.$unknown: r'$unknown',
};
