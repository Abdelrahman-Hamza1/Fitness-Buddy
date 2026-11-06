// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_summary_event_type.dart';
import 'buddy_turn_event.dart';

part 'buddy_summary_event.freezed.dart';
part 'buddy_summary_event.g.dart';

/// The new conversation summary after a compact request (always before done).
@Freezed()
abstract class BuddySummaryEvent with _$BuddySummaryEvent {
  const factory BuddySummaryEvent({
    required BuddySummaryEventType type,
    required String text,
    required int revision,
    required String watermark,
  }) = _BuddySummaryEvent;

  factory BuddySummaryEvent.fromJson(Map<String, Object?> json) =>
      _$BuddySummaryEventFromJson(json);
}
