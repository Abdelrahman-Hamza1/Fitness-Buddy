// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_card_revision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyCardRevision _$BuddyCardRevisionFromJson(Map<String, dynamic> json) =>
    _BuddyCardRevision(
      proposalId: json['proposalId'] as String,
      expectedRevision: (json['expectedRevision'] as num).toInt(),
    );

Map<String, dynamic> _$BuddyCardRevisionToJson(_BuddyCardRevision instance) =>
    <String, dynamic>{
      'proposalId': instance.proposalId,
      'expectedRevision': instance.expectedRevision,
    };
