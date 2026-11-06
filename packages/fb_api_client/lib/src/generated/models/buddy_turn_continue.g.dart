// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_turn_continue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyTurnContinue _$BuddyTurnContinueFromJson(Map<String, dynamic> json) =>
    _BuddyTurnContinue(
      turnId: json['turnId'] as String,
      round: (json['round'] as num).toInt(),
      continuation: json['continuation'] as String,
      results: (json['results'] as List<dynamic>)
          .map((e) => BuddyPhoneToolResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      priorAttempt: json['priorAttempt'] == null
          ? null
          : BuddyPriorAttempt.fromJson(
              json['priorAttempt'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BuddyTurnContinueToJson(_BuddyTurnContinue instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'round': instance.round,
      'continuation': instance.continuation,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'priorAttempt': instance.priorAttempt?.toJson(),
    };
