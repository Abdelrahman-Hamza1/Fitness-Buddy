// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_history_role.dart';
import 'buddy_outcome.dart';

part 'buddy_history_entry.freezed.dart';
part 'buddy_history_entry.g.dart';

@Freezed()
abstract class BuddyHistoryEntry with _$BuddyHistoryEntry {
  const factory BuddyHistoryEntry({
    required String messageId,
    required BuddyHistoryRole role,

    /// The message or reply text as shown (≤ 1000 characters; the phone truncates longer ones).
    required String text,
    required List<BuddyOutcome> outcomes,
  }) = _BuddyHistoryEntry;

  factory BuddyHistoryEntry.fromJson(Map<String, Object?> json) =>
      _$BuddyHistoryEntryFromJson(json);
}
