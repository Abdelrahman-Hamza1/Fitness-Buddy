// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_question_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyQuestionEvent _$BuddyQuestionEventFromJson(Map<String, dynamic> json) =>
    _BuddyQuestionEvent(
      type: BuddyQuestionEventType.fromJson(json['type'] as String),
      text: json['text'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$BuddyQuestionEventToJson(_BuddyQuestionEvent instance) =>
    <String, dynamic>{
      'type': _$BuddyQuestionEventTypeEnumMap[instance.type]!,
      'text': instance.text,
      'options': instance.options,
    };

const _$BuddyQuestionEventTypeEnumMap = {
  BuddyQuestionEventType.question: 'question',
  BuddyQuestionEventType.$unknown: r'$unknown',
};
