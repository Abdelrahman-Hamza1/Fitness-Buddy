// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_start_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmailStartRequest _$EmailStartRequestFromJson(Map<String, dynamic> json) =>
    _EmailStartRequest(
      email: json['email'] as String,
      purpose: json['purpose'] as String,
    );

Map<String, dynamic> _$EmailStartRequestToJson(_EmailStartRequest instance) =>
    <String, dynamic>{'email': instance.email, 'purpose': instance.purpose};
