// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_prior_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyPriorCard _$BuddyPriorCardFromJson(Map<String, dynamic> json) =>
    _BuddyPriorCard(
      proposalId: json['proposalId'] as String,
      status: BuddyPriorCardStatus.fromJson(json['status'] as String),
      revision: (json['revision'] as num).toInt(),
      line: json['line'] as String,
    );

Map<String, dynamic> _$BuddyPriorCardToJson(_BuddyPriorCard instance) =>
    <String, dynamic>{
      'proposalId': instance.proposalId,
      'status': _$BuddyPriorCardStatusEnumMap[instance.status]!,
      'revision': instance.revision,
      'line': instance.line,
    };

const _$BuddyPriorCardStatusEnumMap = {
  BuddyPriorCardStatus.confirmed: 'confirmed',
  BuddyPriorCardStatus.discarded: 'discarded',
  BuddyPriorCardStatus.pending: 'pending',
  BuddyPriorCardStatus.$unknown: r'$unknown',
};
