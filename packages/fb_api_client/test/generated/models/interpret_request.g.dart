// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interpret_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InterpretRequest _$InterpretRequestFromJson(Map<String, dynamic> json) =>
    _InterpretRequest(
      messageId: json['messageId'] as String,
      text: json['text'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      localDate: json['localDate'] as String,
    );

Map<String, dynamic> _$InterpretRequestToJson(_InterpretRequest instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'text': instance.text,
      'sentAt': instance.sentAt.toIso8601String(),
      'localDate': instance.localDate,
    };
