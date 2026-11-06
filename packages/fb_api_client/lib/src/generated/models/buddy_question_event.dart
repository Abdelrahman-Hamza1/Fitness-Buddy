// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_question_event_type.dart';
import 'buddy_turn_event.dart';

part 'buddy_question_event.freezed.dart';
part 'buddy_question_event.g.dart';

/// A question with 2–4 option chips (AI-061/166); a tap is the next message.
@Freezed()
abstract class BuddyQuestionEvent with _$BuddyQuestionEvent {
  const factory BuddyQuestionEvent({
    required BuddyQuestionEventType type,
    required String text,
    required List<String> options,
  }) = _BuddyQuestionEvent;

  factory BuddyQuestionEvent.fromJson(Map<String, Object?> json) =>
      _$BuddyQuestionEventFromJson(json);
}
