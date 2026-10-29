// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_ambiguous_reference_kind.dart';
import 'buddy_diary_patch.dart';
import 'buddy_entry_reference.dart';
import 'buddy_intent.dart';
import 'buddy_reference_operation.dart';

part 'buddy_ambiguous_reference.freezed.dart';
part 'buddy_ambiguous_reference.g.dart';

/// Produced by server policy, never by the model.
@Freezed()
abstract class BuddyAmbiguousReference with _$BuddyAmbiguousReference {
  const factory BuddyAmbiguousReference({
    required BuddyAmbiguousReferenceKind kind,
    required String language,
    required String script,
    required BuddyReferenceOperation operation,

    /// Request recentEntries IDs the message could mean; the app asks which (AI-091).
    required List<String> candidates,
    required BuddyEntryReference reference,

    /// The edit to apply to the chosen entry; null for delete.
    required BuddyDiaryPatch? patch,
  }) = _BuddyAmbiguousReference;

  factory BuddyAmbiguousReference.fromJson(Map<String, Object?> json) =>
      _$BuddyAmbiguousReferenceFromJson(json);
}
