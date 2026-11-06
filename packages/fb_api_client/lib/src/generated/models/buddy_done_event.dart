// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_done_event_type.dart';
import 'buddy_done_reason.dart';
import 'buddy_turn_event.dart';
import 'buddy_turn_usage.dart';

part 'buddy_done_event.freezed.dart';
part 'buddy_done_event.g.dart';

/// Ends the turn.
@Freezed()
abstract class BuddyDoneEvent with _$BuddyDoneEvent {
  const factory BuddyDoneEvent({
    required BuddyDoneEventType type,
    required BuddyDoneReason reason,
    required BuddyTurnUsage usage,
  }) = _BuddyDoneEvent;

  factory BuddyDoneEvent.fromJson(Map<String, Object?> json) =>
      _$BuddyDoneEventFromJson(json);
}
