// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntentLogFood _$IntentLogFoodFromJson(Map<String, dynamic> json) =>
    IntentLogFood(
      kind: json['kind'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      eatenAt: DateTime.parse(json['eatenAt'] as String),
      date: json['date'] as String?,
    );

Map<String, dynamic> _$IntentLogFoodToJson(IntentLogFood instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'eatenAt': instance.eatenAt.toIso8601String(),
      'date': instance.date,
    };

IntentAskQuestion _$IntentAskQuestionFromJson(Map<String, dynamic> json) =>
    IntentAskQuestion(
      kind: json['kind'] as String,
      question: json['question'] as String,
      topic: json['topic'] as String?,
    );

Map<String, dynamic> _$IntentAskQuestionToJson(IntentAskQuestion instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'question': instance.question,
      'topic': instance.topic,
    };

IntentUnknown _$IntentUnknownFromJson(Map<String, dynamic> json) =>
    IntentUnknown(
      kind: json['kind'] as String,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$IntentUnknownToJson(IntentUnknown instance) =>
    <String, dynamic>{'kind': instance.kind, 'reason': instance.reason};

IntentUnrecognized _$IntentUnrecognizedFromJson(Map<String, dynamic> json) =>
    IntentUnrecognized($type: json['kind'] as String?);

Map<String, dynamic> _$IntentUnrecognizedToJson(IntentUnrecognized instance) =>
    <String, dynamic>{'kind': instance.$type};
