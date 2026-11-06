// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_card_revision.dart';
import 'buddy_done_event.dart';
import 'buddy_done_event_type.dart';
import 'buddy_done_reason.dart';
import 'buddy_error_event.dart';
import 'buddy_error_event_type.dart';
import 'buddy_intent.dart';
import 'buddy_phone_tool_call.dart';
import 'buddy_phone_tools_event.dart';
import 'buddy_phone_tools_event_type.dart';
import 'buddy_proposal_event.dart';
import 'buddy_proposal_event_type.dart';
import 'buddy_question_event.dart';
import 'buddy_question_event_type.dart';
import 'buddy_step_code.dart';
import 'buddy_step_event.dart';
import 'buddy_step_event_type.dart';
import 'buddy_summary_event.dart';
import 'buddy_summary_event_type.dart';
import 'buddy_text_event.dart';
import 'buddy_text_event_type.dart';
import 'buddy_trace_event.dart';
import 'buddy_trace_event_type.dart';
import 'buddy_trace_step.dart';
import 'buddy_turn_error_code.dart';
import 'buddy_turn_usage.dart';

part 'buddy_turn_event.freezed.dart';
part 'buddy_turn_event.g.dart';

/// One event of a turn stream (06 §3.3). Text is buffered until it passes the claim renderer and guards; summary always precedes done.
@Freezed(unionKey: 'type', fallbackUnion: 'unrecognized')
sealed class BuddyTurnEvent with _$BuddyTurnEvent {
  @FreezedUnionValue('step')
  const factory BuddyTurnEvent.step({
    required BuddyStepEventType type,
    required BuddyStepCode code,
  }) = BuddyTurnEventStep;

  @FreezedUnionValue('text')
  const factory BuddyTurnEvent.text({
    required BuddyTextEventType type,
    required String text,
  }) = BuddyTurnEventText;

  @FreezedUnionValue('proposal')
  const factory BuddyTurnEvent.proposal({
    required BuddyProposalEventType type,
    required String proposalId,
    required int revision,
    required BuddyCardRevision? replaces,
    required BuddyIntent intent,
  }) = BuddyTurnEventProposal;

  @FreezedUnionValue('question')
  const factory BuddyTurnEvent.question({
    required BuddyQuestionEventType type,
    required String text,
    required List<String> options,
  }) = BuddyTurnEventQuestion;

  @FreezedUnionValue('phoneTools')
  const factory BuddyTurnEvent.phoneTools({
    required BuddyPhoneToolsEventType type,
    required int round,
    required String continuation,
    required List<BuddyPhoneToolCall> calls,
  }) = BuddyTurnEventPhoneTools;

  @FreezedUnionValue('summary')
  const factory BuddyTurnEvent.summary({
    required BuddySummaryEventType type,
    required String text,
    required int revision,
    required String watermark,
  }) = BuddyTurnEventSummary;

  @FreezedUnionValue('trace')
  const factory BuddyTurnEvent.trace({
    required BuddyTraceEventType type,
    required List<BuddyTraceStep> steps,
  }) = BuddyTurnEventTrace;

  @FreezedUnionValue('done')
  const factory BuddyTurnEvent.done({
    required BuddyDoneEventType type,
    required BuddyDoneReason reason,
    required BuddyTurnUsage usage,
  }) = BuddyTurnEventDone;

  @FreezedUnionValue('error')
  const factory BuddyTurnEvent.error({
    required BuddyErrorEventType type,
    required BuddyTurnErrorCode code,
  }) = BuddyTurnEventError;

  const factory BuddyTurnEvent.unrecognized() = BuddyTurnEventUnrecognized;

  factory BuddyTurnEvent.fromJson(Map<String, Object?> json) =>
      _$BuddyTurnEventFromJson(json);
}
