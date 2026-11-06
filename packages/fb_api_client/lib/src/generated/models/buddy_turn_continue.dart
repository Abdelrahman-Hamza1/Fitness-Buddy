// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_result.dart';
import 'buddy_prior_attempt.dart';

part 'buddy_turn_continue.freezed.dart';
part 'buddy_turn_continue.g.dart';

/// Answers a paused round's phone tools (06 §3.2).
@Freezed()
abstract class BuddyTurnContinue with _$BuddyTurnContinue {
  const factory BuddyTurnContinue({
    required String turnId,

    /// The round the phoneTools event announced (1–3).
    required int round,

    /// The phoneTools event's sealed continuation, unchanged.
    required String continuation,
    required List<BuddyPhoneToolResult> results,
    required BuddyPriorAttempt? priorAttempt,
  }) = _BuddyTurnContinue;

  factory BuddyTurnContinue.fromJson(Map<String, Object?> json) =>
      _$BuddyTurnContinueFromJson(json);
}
