// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_question_intent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AskQuestionIntent _$AskQuestionIntentFromJson(Map<String, dynamic> json) =>
    _AskQuestionIntent(
      kind: json['kind'] as String,
      question: json['question'] as String,
      topic: json['topic'] as String?,
    );

Map<String, dynamic> _$AskQuestionIntentToJson(_AskQuestionIntent instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'question': instance.question,
      'topic': instance.topic,
    };
