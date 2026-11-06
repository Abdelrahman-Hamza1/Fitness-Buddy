// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_coverage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyCoverage _$BuddyCoverageFromJson(Map<String, dynamic> json) =>
    _BuddyCoverage(
      days: (json['days'] as num).toInt(),
      loggedDays: (json['loggedDays'] as num).toInt(),
    );

Map<String, dynamic> _$BuddyCoverageToJson(_BuddyCoverage instance) =>
    <String, dynamic>{'days': instance.days, 'loggedDays': instance.loggedDays};
