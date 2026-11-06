// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_trace_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyTraceEvent _$BuddyTraceEventFromJson(Map<String, dynamic> json) =>
    _BuddyTraceEvent(
      type: BuddyTraceEventType.fromJson(json['type'] as String),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => BuddyTraceStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyTraceEventToJson(_BuddyTraceEvent instance) =>
    <String, dynamic>{
      'type': _$BuddyTraceEventTypeEnumMap[instance.type]!,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
    };

const _$BuddyTraceEventTypeEnumMap = {
  BuddyTraceEventType.trace: 'trace',
  BuddyTraceEventType.$unknown: r'$unknown',
};
