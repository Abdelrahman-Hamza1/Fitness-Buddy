// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_query_data_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyQueryDataCall _$BuddyQueryDataCallFromJson(Map<String, dynamic> json) =>
    _BuddyQueryDataCall(
      name: BuddyQueryDataCallName.fromJson(json['name'] as String),
      callId: json['callId'] as String,
      args: BuddyQueryPlan.fromJson(json['args'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyQueryDataCallToJson(_BuddyQueryDataCall instance) =>
    <String, dynamic>{
      'name': _$BuddyQueryDataCallNameEnumMap[instance.name]!,
      'callId': instance.callId,
      'args': instance.args.toJson(),
    };

const _$BuddyQueryDataCallNameEnumMap = {
  BuddyQueryDataCallName.queryData: 'queryData',
  BuddyQueryDataCallName.$unknown: r'$unknown',
};
