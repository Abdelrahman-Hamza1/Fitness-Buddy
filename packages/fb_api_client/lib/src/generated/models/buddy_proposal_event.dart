// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_card_revision.dart';
import 'buddy_intent.dart';
import 'buddy_proposal_event_type.dart';
import 'buddy_turn_event.dart';

part 'buddy_proposal_event.freezed.dart';
part 'buddy_proposal_event.g.dart';

/// A card. proposalId is UUIDv5 of (turnId, round, attempt, index), so a retry never reuses an earlier attempt's IDs. An update keeps an open card's proposalId with revision + 1 and names it in replaces; the phone drops it when expectedRevision isn't the card's current pending revision.
@Freezed()
abstract class BuddyProposalEvent with _$BuddyProposalEvent {
  const factory BuddyProposalEvent({
    required BuddyProposalEventType type,
    required String proposalId,
    required int revision,
    required BuddyCardRevision? replaces,
    required BuddyIntent intent,
  }) = _BuddyProposalEvent;

  factory BuddyProposalEvent.fromJson(Map<String, Object?> json) =>
      _$BuddyProposalEventFromJson(json);
}
