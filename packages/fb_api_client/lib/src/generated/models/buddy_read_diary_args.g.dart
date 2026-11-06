// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_diary_args.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadDiaryArgs _$BuddyReadDiaryArgsFromJson(Map<String, dynamic> json) =>
    _BuddyReadDiaryArgs(
      dateHint: json['dateHint'] as String?,
      range: json['range'] == null
          ? null
          : BuddyDateRange.fromJson(json['range'] as Map<String, dynamic>),
      slotHint: json['slotHint'] as String?,
      query: json['query'] as String?,
    );

Map<String, dynamic> _$BuddyReadDiaryArgsToJson(_BuddyReadDiaryArgs instance) =>
    <String, dynamic>{
      'dateHint': instance.dateHint,
      'range': instance.range?.toJson(),
      'slotHint': instance.slotHint,
      'query': instance.query,
    };
