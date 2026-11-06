// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_turn_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyTurnSnapshot _$BuddyTurnSnapshotFromJson(Map<String, dynamic> json) =>
    _BuddyTurnSnapshot(
      now: DateTime.parse(json['now'] as String),
      tzOffsetMin: (json['tzOffsetMin'] as num).toInt(),
      slots: (json['slots'] as List<dynamic>)
          .map((e) => BuddySlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      today: BuddyDayTotals.fromJson(json['today'] as Map<String, dynamic>),
      openCards: (json['openCards'] as List<dynamic>)
          .map((e) => BuddyOpenCard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyTurnSnapshotToJson(_BuddyTurnSnapshot instance) =>
    <String, dynamic>{
      'now': instance.now.toIso8601String(),
      'tzOffsetMin': instance.tzOffsetMin,
      'slots': instance.slots.map((e) => e.toJson()).toList(),
      'today': instance.today.toJson(),
      'openCards': instance.openCards.map((e) => e.toJson()).toList(),
    };
