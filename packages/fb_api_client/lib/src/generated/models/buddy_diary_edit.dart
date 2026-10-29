// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_diary_edit_kind.dart';
import 'buddy_diary_patch.dart';
import 'buddy_entry_reference.dart';
import 'buddy_intent.dart';

part 'buddy_diary_edit.freezed.dart';
part 'buddy_diary_edit.g.dart';

@Freezed()
abstract class BuddyDiaryEdit with _$BuddyDiaryEdit {
  const factory BuddyDiaryEdit({
    required BuddyDiaryEditKind kind,
    required String language,
    required String script,

    /// Request recentEntries IDs to change. Empty: the app looks the entries up from reference's day/slot hints and asks.
    required List<String> targets,
    required BuddyEntryReference reference,
    required BuddyDiaryPatch patch,
  }) = _BuddyDiaryEdit;

  factory BuddyDiaryEdit.fromJson(Map<String, Object?> json) =>
      _$BuddyDiaryEditFromJson(json);
}
