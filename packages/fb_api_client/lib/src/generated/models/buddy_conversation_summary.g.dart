// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_conversation_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyConversationSummary _$BuddyConversationSummaryFromJson(
  Map<String, dynamic> json,
) => _BuddyConversationSummary(
  text: json['text'] as String,
  revision: (json['revision'] as num).toInt(),
  watermark: json['watermark'] as String,
);

Map<String, dynamic> _$BuddyConversationSummaryToJson(
  _BuddyConversationSummary instance,
) => <String, dynamic>{
  'text': instance.text,
  'revision': instance.revision,
  'watermark': instance.watermark,
};
