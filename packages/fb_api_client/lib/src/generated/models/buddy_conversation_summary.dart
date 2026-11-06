// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_conversation_summary.freezed.dart';
part 'buddy_conversation_summary.g.dart';

@Freezed()
abstract class BuddyConversationSummary with _$BuddyConversationSummary {
  const factory BuddyConversationSummary({
    required String text,
    required int revision,

    /// The last summarised chat message ID.
    required String watermark,
  }) = _BuddyConversationSummary;

  factory BuddyConversationSummary.fromJson(Map<String, Object?> json) =>
      _$BuddyConversationSummaryFromJson(json);
}
