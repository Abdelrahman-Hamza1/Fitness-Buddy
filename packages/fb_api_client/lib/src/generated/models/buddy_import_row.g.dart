// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_import_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyImportRow _$BuddyImportRowFromJson(Map<String, dynamic> json) =>
    _BuddyImportRow(
      date: json['date'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      original: json['original'] as String,
    );

Map<String, dynamic> _$BuddyImportRowToJson(_BuddyImportRow instance) =>
    <String, dynamic>{
      'date': instance.date,
      'value': instance.value,
      'unit': instance.unit,
      'original': instance.original,
    };
