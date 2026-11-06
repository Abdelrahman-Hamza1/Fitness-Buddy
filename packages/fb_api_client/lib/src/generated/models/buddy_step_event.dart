// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_step_code.dart';
import 'buddy_step_event_type.dart';
import 'buddy_turn_event.dart';

part 'buddy_step_event.freezed.dart';
part 'buddy_step_event.g.dart';

/// A live step line (AI-170); the app shows an ARB text per code.
@Freezed()
abstract class BuddyStepEvent with _$BuddyStepEvent {
  const factory BuddyStepEvent({
    required BuddyStepEventType type,
    required BuddyStepCode code,
  }) = _BuddyStepEvent;

  factory BuddyStepEvent.fromJson(Map<String, Object?> json) =>
      _$BuddyStepEventFromJson(json);
}
