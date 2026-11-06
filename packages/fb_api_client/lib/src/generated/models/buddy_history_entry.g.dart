// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyHistoryEntry _$BuddyHistoryEntryFromJson(Map<String, dynamic> json) =>
    _BuddyHistoryEntry(
      messageId: json['messageId'] as String,
      role: BuddyHistoryRole.fromJson(json['role'] as String),
      text: json['text'] as String,
      outcomes: (json['outcomes'] as List<dynamic>)
          .map((e) => BuddyOutcome.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyHistoryEntryToJson(_BuddyHistoryEntry instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'role': _$BuddyHistoryRoleEnumMap[instance.role]!,
      'text': instance.text,
      'outcomes': instance.outcomes.map((e) => e.toJson()).toList(),
    };

const _$BuddyHistoryRoleEnumMap = {
  BuddyHistoryRole.user: 'user',
  BuddyHistoryRole.buddy: 'buddy',
  BuddyHistoryRole.$unknown: r'$unknown',
};
