// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CurrentAccount _$CurrentAccountFromJson(Map<String, dynamic> json) =>
    _CurrentAccount(
      userId: json['userId'] as String,
      isAnonymous: json['isAnonymous'] as bool,
      status: json['status'] as String,
    );

Map<String, dynamic> _$CurrentAccountToJson(_CurrentAccount instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'isAnonymous': instance.isAnonymous,
      'status': instance.status,
    };
