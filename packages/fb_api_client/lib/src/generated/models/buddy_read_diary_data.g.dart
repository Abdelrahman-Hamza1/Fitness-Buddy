// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_read_diary_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyReadDiaryData _$BuddyReadDiaryDataFromJson(Map<String, dynamic> json) =>
    _BuddyReadDiaryData(
      entries: (json['entries'] as List<dynamic>)
          .map((e) => BuddyDiaryRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      truncated: json['truncated'] as bool,
    );

Map<String, dynamic> _$BuddyReadDiaryDataToJson(_BuddyReadDiaryData instance) =>
    <String, dynamic>{
      'entries': instance.entries.map((e) => e.toJson()).toList(),
      'truncated': instance.truncated,
    };
