// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_turn_start.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyTurnStart _$BuddyTurnStartFromJson(
  Map<String, dynamic> json,
) => _BuddyTurnStart(
  turnId: json['turnId'] as String,
  mode: BuddyTurnMode.fromJson(json['mode'] as String),
  message: BuddyTurnMessage.fromJson(json['message'] as Map<String, dynamic>),
  history: (json['history'] as List<dynamic>)
      .map((e) => BuddyHistoryEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  summary: json['summary'] == null
      ? null
      : BuddyConversationSummary.fromJson(
          json['summary'] as Map<String, dynamic>,
        ),
  compact: json['compact'] == null
      ? null
      : BuddyCompaction.fromJson(json['compact'] as Map<String, dynamic>),
  personal: (json['personal'] as List<dynamic>)
      .map((e) => BuddyPersonalItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  profile: BuddyTurnProfile.fromJson(json['profile'] as Map<String, dynamic>),
  snapshot: BuddyTurnSnapshot.fromJson(
    json['snapshot'] as Map<String, dynamic>,
  ),
  ackTurn: json['ackTurn'] == null
      ? null
      : BuddyTurnReference.fromJson(json['ackTurn'] as Map<String, dynamic>),
  priorAttempt: json['priorAttempt'] == null
      ? null
      : BuddyPriorAttempt.fromJson(
          json['priorAttempt'] as Map<String, dynamic>,
        ),
  trace: json['trace'] as bool,
  weekly: json['weekly'] == null
      ? null
      : BuddyWeeklySummary.fromJson(json['weekly'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyTurnStartToJson(_BuddyTurnStart instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'mode': _$BuddyTurnModeEnumMap[instance.mode]!,
      'message': instance.message.toJson(),
      'history': instance.history.map((e) => e.toJson()).toList(),
      'summary': instance.summary?.toJson(),
      'compact': instance.compact?.toJson(),
      'personal': instance.personal.map((e) => e.toJson()).toList(),
      'profile': instance.profile.toJson(),
      'snapshot': instance.snapshot.toJson(),
      'ackTurn': instance.ackTurn?.toJson(),
      'priorAttempt': instance.priorAttempt?.toJson(),
      'trace': instance.trace,
      'weekly': instance.weekly?.toJson(),
    };

const _$BuddyTurnModeEnumMap = {
  BuddyTurnMode.chat: 'chat',
  BuddyTurnMode.weeklyReview: 'weeklyReview',
  BuddyTurnMode.$unknown: r'$unknown',
};
