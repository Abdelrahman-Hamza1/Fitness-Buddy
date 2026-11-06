// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_diary_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDiaryRow _$BuddyDiaryRowFromJson(Map<String, dynamic> json) =>
    _BuddyDiaryRow(
      name: json['name'] as String,
      id: json['id'] as String,
      date: json['date'] as String,
      slot: json['slot'] as String,
      grams: (json['grams'] as num?)?.toDouble(),
      kcal: (json['kcal'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BuddyDiaryRowToJson(_BuddyDiaryRow instance) =>
    <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
      'date': instance.date,
      'slot': instance.slot,
      'grams': instance.grams,
      'kcal': instance.kcal,
    };
