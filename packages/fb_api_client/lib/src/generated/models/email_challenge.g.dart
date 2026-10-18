// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_challenge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmailChallenge _$EmailChallengeFromJson(Map<String, dynamic> json) =>
    _EmailChallenge(
      challengeId: json['challengeId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$EmailChallengeToJson(_EmailChallenge instance) =>
    <String, dynamic>{
      'challengeId': instance.challengeId,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
