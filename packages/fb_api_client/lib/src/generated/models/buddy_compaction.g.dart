// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_compaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyCompaction _$BuddyCompactionFromJson(Map<String, dynamic> json) =>
    _BuddyCompaction(
      evicted: (json['evicted'] as List<dynamic>)
          .map((e) => BuddyHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      previousRevision: (json['previousRevision'] as num).toInt(),
    );

Map<String, dynamic> _$BuddyCompactionToJson(_BuddyCompaction instance) =>
    <String, dynamic>{
      'evicted': instance.evicted.map((e) => e.toJson()).toList(),
      'previousRevision': instance.previousRevision,
    };
