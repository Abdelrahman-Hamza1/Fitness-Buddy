// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_day_hint.dart';
import 'buddy_intent.dart';
import 'buddy_saved_meal_create_kind.dart';

part 'buddy_saved_meal_create.freezed.dart';
part 'buddy_saved_meal_create.g.dart';

/// Save a meal as ... (DY-031). Exactly one source: activeProposal, targets or source.
@Freezed()
abstract class BuddySavedMealCreate with _$BuddySavedMealCreate {
  const factory BuddySavedMealCreate({
    required BuddySavedMealCreateKind kind,
    required String language,
    required String script,

    /// Never null: a nameless "save this" is clarified.
    required String name,

    /// The request activeProposal ("save this").
    required String? activeProposal,

    /// Request recentEntries IDs to save.
    required List<String> targets,

    /// Day/slot to save from, for the app's local lookup.
    required BuddyDayHint? source,
  }) = _BuddySavedMealCreate;

  factory BuddySavedMealCreate.fromJson(Map<String, Object?> json) =>
      _$BuddySavedMealCreateFromJson(json);
}
