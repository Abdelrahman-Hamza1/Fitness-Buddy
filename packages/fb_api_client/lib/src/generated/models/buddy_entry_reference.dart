// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_reference_scope.dart';

part 'buddy_entry_reference.freezed.dart';
part 'buddy_entry_reference.g.dart';

/// How the message referred to diary entries; the server maps it to request entry IDs (AI-091).
@Freezed()
abstract class BuddyEntryReference with _$BuddyEntryReference {
  const factory BuddyEntryReference({
    /// The user's words for the entry.
    required String mention,

    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,

    /// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
    required String? slotHint,
    required BuddyReferenceScope scope,
  }) = _BuddyEntryReference;

  factory BuddyEntryReference.fromJson(Map<String, Object?> json) =>
      _$BuddyEntryReferenceFromJson(json);
}
