// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_trace_event_type.dart';
import 'buddy_trace_step.dart';
import 'buddy_turn_event.dart';

part 'buddy_trace_event.freezed.dart';
part 'buddy_trace_event.g.dart';

/// Dev trace (AI-172): tool, arguments and result summary per step, for the phone only.
@Freezed()
abstract class BuddyTraceEvent with _$BuddyTraceEvent {
  const factory BuddyTraceEvent({
    required BuddyTraceEventType type,
    required List<BuddyTraceStep> steps,
  }) = _BuddyTraceEvent;

  factory BuddyTraceEvent.fromJson(Map<String, Object?> json) =>
      _$BuddyTraceEventFromJson(json);
}
