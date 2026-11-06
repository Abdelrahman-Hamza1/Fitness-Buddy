// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_compaction.dart';
import 'buddy_conversation_summary.dart';
import 'buddy_history_entry.dart';
import 'buddy_personal_item.dart';
import 'buddy_prior_attempt.dart';
import 'buddy_turn_message.dart';
import 'buddy_turn_mode.dart';
import 'buddy_turn_profile.dart';
import 'buddy_turn_reference.dart';
import 'buddy_turn_snapshot.dart';

part 'buddy_turn_start.freezed.dart';
part 'buddy_turn_start.g.dart';

/// Starts a turn (06 §3.1). Lists are bounded by the schema; texts are user content and never logged.
@Freezed()
abstract class BuddyTurnStart with _$BuddyTurnStart {
  const factory BuddyTurnStart({
    /// The user chat message ID (UUIDv7); equals Idempotency-Key and names the turn in SSE ids and proposal IDs.
    required String turnId,

    /// chat, or weeklyReview (B26: aggregates only, no phone tools).
    required BuddyTurnMode mode,
    required BuddyTurnMessage message,

    /// The last 12 chat entries, oldest first, with their card outcomes (TD-126).
    required List<BuddyHistoryEntry> history,

    /// The phone's current conversation summary, or null.
    required BuddyConversationSummary? summary,

    /// Entries evicted past the summary's watermark (the phone owns compaction, 06 §6.1); the server answers with a summary event before done.
    required BuddyCompaction? compact,

    /// The personal slice: up to 20 personal foods, saved meals, open batches and usual meals pre-matched on the phone against the message tokens (fb_text normalization), with their facts. Resolved before the catalog (AI-070).
    required List<BuddyPersonalItem> personal,
    required BuddyTurnProfile profile,
    required BuddyTurnSnapshot snapshot,

    /// The previous turn, acknowledging its final round (06 §3.4); null when there is none.
    required BuddyTurnReference? ackTurn,

    /// Retries only: the cards the earlier attempt of this round produced and what happened to them.
    required BuddyPriorAttempt? priorAttempt,

    /// Dev builds only; honoured only when the server enables Buddy:Agent:TraceEnabled. Adds trace events for the phone, never logged.
    required bool trace,
  }) = _BuddyTurnStart;

  factory BuddyTurnStart.fromJson(Map<String, Object?> json) =>
      _$BuddyTurnStartFromJson(json);
}
