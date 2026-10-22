// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_interpretation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyInterpretation _$BuddyInterpretationFromJson(Map<String, dynamic> json) =>
    _BuddyInterpretation(
      promptVersion: json['promptVersion'] as String,
      model: json['model'] as String,
      intents: (json['intents'] as List<dynamic>)
          .map((e) => BuddyIntent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyInterpretationToJson(
  _BuddyInterpretation instance,
) => <String, dynamic>{
  'promptVersion': instance.promptVersion,
  'model': instance.model,
  'intents': instance.intents.map((e) => e.toJson()).toList(),
};
