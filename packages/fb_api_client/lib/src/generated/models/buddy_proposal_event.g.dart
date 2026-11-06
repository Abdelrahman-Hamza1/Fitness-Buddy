// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_proposal_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyProposalEvent _$BuddyProposalEventFromJson(Map<String, dynamic> json) =>
    _BuddyProposalEvent(
      type: BuddyProposalEventType.fromJson(json['type'] as String),
      proposalId: json['proposalId'] as String,
      revision: (json['revision'] as num).toInt(),
      replaces: json['replaces'] == null
          ? null
          : BuddyCardRevision.fromJson(
              json['replaces'] as Map<String, dynamic>,
            ),
      intent: BuddyIntent.fromJson(json['intent'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyProposalEventToJson(_BuddyProposalEvent instance) =>
    <String, dynamic>{
      'type': _$BuddyProposalEventTypeEnumMap[instance.type]!,
      'proposalId': instance.proposalId,
      'revision': instance.revision,
      'replaces': instance.replaces?.toJson(),
      'intent': instance.intent.toJson(),
    };

const _$BuddyProposalEventTypeEnumMap = {
  BuddyProposalEventType.proposal: 'proposal',
  BuddyProposalEventType.$unknown: r'$unknown',
};
