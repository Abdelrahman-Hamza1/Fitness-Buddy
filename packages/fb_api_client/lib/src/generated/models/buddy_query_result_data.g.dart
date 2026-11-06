// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_query_result_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyQueryResultData _$BuddyQueryResultDataFromJson(
  Map<String, dynamic> json,
) => _BuddyQueryResultData(
  claims: (json['claims'] as List<dynamic>)
      .map((e) => BuddyClaimValue.fromJson(e as Map<String, dynamic>))
      .toList(),
  coverage: BuddyCoverage.fromJson(json['coverage'] as Map<String, dynamic>),
  link: json['link'] == null
      ? null
      : BuddyQueryLink.fromJson(json['link'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyQueryResultDataToJson(
  _BuddyQueryResultData instance,
) => <String, dynamic>{
  'claims': instance.claims.map((e) => e.toJson()).toList(),
  'coverage': instance.coverage.toJson(),
  'link': instance.link?.toJson(),
};
