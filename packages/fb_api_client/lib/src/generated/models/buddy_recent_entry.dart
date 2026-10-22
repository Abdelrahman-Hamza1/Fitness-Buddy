// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_recent_entry.freezed.dart';
part 'buddy_recent_entry.g.dart';

@Freezed()
abstract class BuddyRecentEntry with _$BuddyRecentEntry {
  const factory BuddyRecentEntry({
    required String id,
    required String date,
    required String slot,
    required String name,
    required double? grams,
  }) = _BuddyRecentEntry;

  factory BuddyRecentEntry.fromJson(Map<String, Object?> json) =>
      _$BuddyRecentEntryFromJson(json);
}
