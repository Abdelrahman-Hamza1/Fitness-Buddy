// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_text_event_type.dart';
import 'buddy_turn_event.dart';

part 'buddy_text_event.freezed.dart';
part 'buddy_text_event.g.dart';

/// A chunk of the rendered, guarded reply; chunks arrive in order.
@Freezed()
abstract class BuddyTextEvent with _$BuddyTextEvent {
  const factory BuddyTextEvent({
    required BuddyTextEventType type,
    required String text,
  }) = _BuddyTextEvent;

  factory BuddyTextEvent.fromJson(Map<String, Object?> json) =>
      _$BuddyTextEventFromJson(json);
}
