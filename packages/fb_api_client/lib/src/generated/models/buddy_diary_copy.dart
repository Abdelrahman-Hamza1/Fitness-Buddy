// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_day_hint.dart';
import 'buddy_diary_copy_kind.dart';
import 'buddy_intent.dart';

part 'buddy_diary_copy.freezed.dart';
part 'buddy_diary_copy.g.dart';

/// Copy entries from source to target. A null target member means today, the source's slot, or now. A null source.slotHint is clarified in R1 (no whole-day copy).
@Freezed()
abstract class BuddyDiaryCopy with _$BuddyDiaryCopy {
  const factory BuddyDiaryCopy({
    required BuddyDiaryCopyKind kind,
    required String language,
    required String script,

    /// Where to copy from.
    required BuddyDayHint source,

    /// Where to copy to.
    required BuddyDayHint target,
  }) = _BuddyDiaryCopy;

  factory BuddyDiaryCopy.fromJson(Map<String, Object?> json) =>
      _$BuddyDiaryCopyFromJson(json);
}
