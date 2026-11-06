// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_turn_usage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyTurnUsage _$BuddyTurnUsageFromJson(Map<String, dynamic> json) =>
    _BuddyTurnUsage(
      sends: (json['sends'] as num).toInt(),
      inputTokens: (json['inputTokens'] as num).toInt(),
      outputTokens: (json['outputTokens'] as num).toInt(),
    );

Map<String, dynamic> _$BuddyTurnUsageToJson(_BuddyTurnUsage instance) =>
    <String, dynamic>{
      'sends': instance.sends,
      'inputTokens': instance.inputTokens,
      'outputTokens': instance.outputTokens,
    };
