// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_outcome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyOutcome _$BuddyOutcomeFromJson(Map<String, dynamic> json) =>
    _BuddyOutcome(
      kind: json['kind'] as String,
      proposalId: json['proposalId'] as String,
      status: BuddyOutcomeStatus.fromJson(json['status'] as String),
      label: json['label'] as String,
    );

Map<String, dynamic> _$BuddyOutcomeToJson(_BuddyOutcome instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'proposalId': instance.proposalId,
      'status': _$BuddyOutcomeStatusEnumMap[instance.status]!,
      'label': instance.label,
    };

const _$BuddyOutcomeStatusEnumMap = {
  BuddyOutcomeStatus.confirmed: 'confirmed',
  BuddyOutcomeStatus.edited: 'edited',
  BuddyOutcomeStatus.discarded: 'discarded',
  BuddyOutcomeStatus.pending: 'pending',
  BuddyOutcomeStatus.$unknown: r'$unknown',
};
