// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_active_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyActiveCard _$BuddyActiveCardFromJson(Map<String, dynamic> json) =>
    _BuddyActiveCard(
      slot: json['slot'] as String?,
      time: json['time'] as String?,
      lines: (json['lines'] as List<dynamic>)
          .map((e) => BuddyActiveCardLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyActiveCardToJson(_BuddyActiveCard instance) =>
    <String, dynamic>{
      'slot': instance.slot,
      'time': instance.time,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
    };
