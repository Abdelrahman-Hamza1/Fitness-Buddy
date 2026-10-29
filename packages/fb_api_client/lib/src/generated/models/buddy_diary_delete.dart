// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_diary_delete_kind.dart';
import 'buddy_entry_reference.dart';
import 'buddy_intent.dart';

part 'buddy_diary_delete.freezed.dart';
part 'buddy_diary_delete.g.dart';

@Freezed()
abstract class BuddyDiaryDelete with _$BuddyDiaryDelete {
  const factory BuddyDiaryDelete({
    required BuddyDiaryDeleteKind kind,
    required String language,
    required String script,

    /// Request recentEntries IDs to delete. Empty: the app looks the entries up from reference's day/slot hints and asks.
    required List<String> targets,
    required BuddyEntryReference reference,
  }) = _BuddyDiaryDelete;

  factory BuddyDiaryDelete.fromJson(Map<String, Object?> json) =>
      _$BuddyDiaryDeleteFromJson(json);
}
