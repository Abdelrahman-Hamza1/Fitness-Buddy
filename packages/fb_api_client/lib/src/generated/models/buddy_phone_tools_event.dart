// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_call.dart';
import 'buddy_phone_tools_event_type.dart';
import 'buddy_turn_event.dart';

part 'buddy_phone_tools_event.freezed.dart';
part 'buddy_phone_tools_event.g.dart';

/// Ends the round: the phone runs the calls under its scopes and posts continue with round and continuation.
@Freezed()
abstract class BuddyPhoneToolsEvent with _$BuddyPhoneToolsEvent {
  const factory BuddyPhoneToolsEvent({
    required BuddyPhoneToolsEventType type,
    required int round,
    required String continuation,
    required List<BuddyPhoneToolCall> calls,
  }) = _BuddyPhoneToolsEvent;

  factory BuddyPhoneToolsEvent.fromJson(Map<String, Object?> json) =>
      _$BuddyPhoneToolsEventFromJson(json);
}
