// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interpret_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InterpretRequest _$InterpretRequestFromJson(Map<String, dynamic> json) =>
    _InterpretRequest(
      requestId: json['requestId'] as String,
      text: json['text'] as String,
      now: DateTime.parse(json['now'] as String),
      tzOffsetMin: (json['tzOffsetMin'] as num).toInt(),
      ramadan: BuddyRamadan.fromJson(json['ramadan'] as Map<String, dynamic>),
      slots: (json['slots'] as List<dynamic>)
          .map((e) => BuddySlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeProposal: json['activeProposal'] as String?,
      context: BuddyContext.fromJson(json['context'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InterpretRequestToJson(_InterpretRequest instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'text': instance.text,
      'now': instance.now.toIso8601String(),
      'tzOffsetMin': instance.tzOffsetMin,
      'ramadan': instance.ramadan.toJson(),
      'slots': instance.slots.map((e) => e.toJson()).toList(),
      'activeProposal': instance.activeProposal,
      'context': instance.context.toJson(),
    };
