// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_identity_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LinkIdentityRequest _$LinkIdentityRequestFromJson(Map<String, dynamic> json) =>
    _LinkIdentityRequest(
      idToken: json['idToken'] as String?,
      challengeId: json['challengeId'] as String?,
      code: json['code'] as String?,
    );

Map<String, dynamic> _$LinkIdentityRequestToJson(
  _LinkIdentityRequest instance,
) => <String, dynamic>{
  'idToken': instance.idToken,
  'challengeId': instance.challengeId,
  'code': instance.code,
};
