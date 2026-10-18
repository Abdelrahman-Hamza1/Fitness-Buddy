// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_verify_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmailVerifyRequest _$EmailVerifyRequestFromJson(Map<String, dynamic> json) =>
    _EmailVerifyRequest(
      challengeId: json['challengeId'] as String,
      code: json['code'] as String,
    );

Map<String, dynamic> _$EmailVerifyRequestToJson(_EmailVerifyRequest instance) =>
    <String, dynamic>{
      'challengeId': instance.challengeId,
      'code': instance.code,
    };
