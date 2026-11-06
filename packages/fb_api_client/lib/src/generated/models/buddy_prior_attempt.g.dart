// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_prior_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyPriorAttempt _$BuddyPriorAttemptFromJson(Map<String, dynamic> json) =>
    _BuddyPriorAttempt(
      attempt: (json['attempt'] as num).toInt(),
      cards: (json['cards'] as List<dynamic>)
          .map((e) => BuddyPriorCard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyPriorAttemptToJson(_BuddyPriorAttempt instance) =>
    <String, dynamic>{
      'attempt': instance.attempt,
      'cards': instance.cards.map((e) => e.toJson()).toList(),
    };
