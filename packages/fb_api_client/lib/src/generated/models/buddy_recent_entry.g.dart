// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_recent_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyRecentEntry _$BuddyRecentEntryFromJson(Map<String, dynamic> json) =>
    _BuddyRecentEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      slot: json['slot'] as String,
      name: json['name'] as String,
      grams: (json['grams'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BuddyRecentEntryToJson(_BuddyRecentEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'slot': instance.slot,
      'name': instance.name,
      'grams': instance.grams,
    };
