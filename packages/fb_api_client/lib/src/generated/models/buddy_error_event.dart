// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_error_event_type.dart';
import 'buddy_turn_error_code.dart';
import 'buddy_turn_event.dart';

part 'buddy_error_event.freezed.dart';
part 'buddy_error_event.g.dart';

/// Ends the round with an error: unavailable, timeout, invalid (continue results don't match the pending calls), roundAlreadyRan, expired (a third attempt or an expired continuation). The message stays pending or failed (AI-177).
@Freezed()
abstract class BuddyErrorEvent with _$BuddyErrorEvent {
  const factory BuddyErrorEvent({
    required BuddyErrorEventType type,
    required BuddyTurnErrorCode code,
  }) = _BuddyErrorEvent;

  factory BuddyErrorEvent.fromJson(Map<String, Object?> json) =>
      _$BuddyErrorEventFromJson(json);
}
