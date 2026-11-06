// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_open_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyOpenCard _$BuddyOpenCardFromJson(Map<String, dynamic> json) =>
    _BuddyOpenCard(
      kind: json['kind'] as String,
      proposalId: json['proposalId'] as String,
      revision: (json['revision'] as num).toInt(),
      summary: json['summary'] as String,
    );

Map<String, dynamic> _$BuddyOpenCardToJson(_BuddyOpenCard instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'proposalId': instance.proposalId,
      'revision': instance.revision,
      'summary': instance.summary,
    };
