// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_history_entry.dart';

part 'buddy_compaction.freezed.dart';
part 'buddy_compaction.g.dart';

@Freezed()
abstract class BuddyCompaction with _$BuddyCompaction {
  const factory BuddyCompaction({
    required List<BuddyHistoryEntry> evicted,

    /// The summary revision the phone holds (0 when it has none); the returned summary has previousRevision + 1 and is stored only if the phone's revision still matches.
    required int previousRevision,
  }) = _BuddyCompaction;

  factory BuddyCompaction.fromJson(Map<String, Object?> json) =>
      _$BuddyCompactionFromJson(json);
}
