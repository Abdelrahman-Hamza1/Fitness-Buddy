// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interpretation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Interpretation _$InterpretationFromJson(Map<String, dynamic> json) =>
    _Interpretation(
      id: json['id'] as String,
      intents: (json['intents'] as List<dynamic>)
          .map((e) => Intent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InterpretationToJson(_Interpretation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'intents': instance.intents.map((e) => e.toJson()).toList(),
    };
