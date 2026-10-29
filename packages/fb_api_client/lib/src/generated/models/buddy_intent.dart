// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_ambiguous_reference.dart';
import 'buddy_ambiguous_reference_kind.dart';
import 'buddy_amount.dart';
import 'buddy_batch.dart';
import 'buddy_batch_close.dart';
import 'buddy_batch_close_kind.dart';
import 'buddy_batch_kind.dart';
import 'buddy_batch_path.dart';
import 'buddy_batch_portion.dart';
import 'buddy_batch_portion_kind.dart';
import 'buddy_clarify.dart';
import 'buddy_clarify_kind.dart';
import 'buddy_day_hint.dart';
import 'buddy_diary_copy.dart';
import 'buddy_diary_copy_kind.dart';
import 'buddy_diary_delete.dart';
import 'buddy_diary_delete_kind.dart';
import 'buddy_diary_edit.dart';
import 'buddy_diary_edit_kind.dart';
import 'buddy_diary_patch.dart';
import 'buddy_entry_reference.dart';
import 'buddy_food_item.dart';
import 'buddy_food_log.dart';
import 'buddy_food_log_kind.dart';
import 'buddy_medical.dart';
import 'buddy_medical_kind.dart';
import 'buddy_memory_change.dart';
import 'buddy_memory_change_kind.dart';
import 'buddy_memory_dimension.dart';
import 'buddy_memory_kind.dart';
import 'buddy_memory_operation.dart';
import 'buddy_out_of_scope.dart';
import 'buddy_out_of_scope_kind.dart';
import 'buddy_personal_food_create.dart';
import 'buddy_personal_food_create_kind.dart';
import 'buddy_portion.dart';
import 'buddy_reference_operation.dart';
import 'buddy_saved_meal_create.dart';
import 'buddy_saved_meal_create_kind.dart';
import 'buddy_saved_meal_log.dart';
import 'buddy_saved_meal_log_kind.dart';
import 'buddy_share.dart';
import 'buddy_stated_nutrients.dart';
import 'buddy_weigh_in.dart';
import 'buddy_weigh_in_kind.dart';

part 'buddy_intent.freezed.dart';
part 'buddy_intent.g.dart';

@Freezed(unionKey: 'kind', fallbackUnion: 'unrecognized')
sealed class BuddyIntent with _$BuddyIntent {
  @FreezedUnionValue('foodLog')
  const factory BuddyIntent.foodLog({
    required BuddyFoodLogKind kind,
    required String language,
    required String script,

    /// Literal time phrase as the user said it (B08); the app resolves it.
    required String? timeHint,

    /// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
    required String? slotHint,

    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,
    required String? dishGroup,
    required List<BuddyFoodItem> items,
  }) = BuddyIntentFoodLog;

  @FreezedUnionValue('clarify')
  const factory BuddyIntent.clarify({
    required BuddyClarifyKind kind,
    required String language,
    required String script,
    required String reason,
  }) = BuddyIntentClarify;

  @FreezedUnionValue('outOfScope')
  const factory BuddyIntent.outOfScope({
    required BuddyOutOfScopeKind kind,
    required String language,
    required String script,
    required String reason,
  }) = BuddyIntentOutOfScope;

  @FreezedUnionValue('medical')
  const factory BuddyIntent.medical({
    required BuddyMedicalKind kind,
    required String language,
    required String script,
  }) = BuddyIntentMedical;

  @FreezedUnionValue('weighIn')
  const factory BuddyIntent.weighIn({
    required BuddyWeighInKind kind,
    required String language,
    required String script,
    required double value,
    required String unit,

    /// Literal time phrase as the user said it (B08); the app resolves it.
    required String? timeHint,

    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,
  }) = BuddyIntentWeighIn;

  @FreezedUnionValue('diaryEdit')
  const factory BuddyIntent.diaryEdit({
    required BuddyDiaryEditKind kind,
    required String language,
    required String script,

    /// Request recentEntries IDs to change. Empty: the app looks the entries up from reference's day/slot hints and asks.
    required List<String> targets,
    required BuddyEntryReference reference,
    required BuddyDiaryPatch patch,
  }) = BuddyIntentDiaryEdit;

  @FreezedUnionValue('diaryDelete')
  const factory BuddyIntent.diaryDelete({
    required BuddyDiaryDeleteKind kind,
    required String language,
    required String script,

    /// Request recentEntries IDs to delete. Empty: the app looks the entries up from reference's day/slot hints and asks.
    required List<String> targets,
    required BuddyEntryReference reference,
  }) = BuddyIntentDiaryDelete;

  @FreezedUnionValue('ambiguousReference')
  const factory BuddyIntent.ambiguousReference({
    required BuddyAmbiguousReferenceKind kind,
    required String language,
    required String script,
    required BuddyReferenceOperation operation,

    /// Request recentEntries IDs the message could mean; the app asks which (AI-091).
    required List<String> candidates,
    required BuddyEntryReference reference,

    /// The edit to apply to the chosen entry; null for delete.
    required BuddyDiaryPatch? patch,
  }) = BuddyIntentAmbiguousReference;

  @FreezedUnionValue('diaryCopy')
  const factory BuddyIntent.diaryCopy({
    required BuddyDiaryCopyKind kind,
    required String language,
    required String script,

    /// Where to copy from.
    required BuddyDayHint source,

    /// Where to copy to.
    required BuddyDayHint target,
  }) = BuddyIntentDiaryCopy;

  @FreezedUnionValue('memoryChange')
  const factory BuddyIntent.memoryChange({
    required BuddyMemoryChangeKind kind,
    required String language,
    required String script,
    required BuddyMemoryOperation operation,
    required BuddyMemoryKind memoryKind,

    /// The food or name the statement is about, as the user said it.
    required String? subject,
    required BuddyMemoryDimension? dimension,

    /// Closed for state (raw, cooked, dry, drained, fried) and fat (none, oil); literal otherwise (alias, brand, nickname, variant).
    required String? value,

    /// The portion, or the fat quantity. Authoritative; food.amount is ignored.
    required BuddyAmount? amount,

    /// The subject food when it matches a real food; never an estimate.
    required BuddyFoodItem? food,
  }) = BuddyIntentMemoryChange;

  @FreezedUnionValue('batch')
  const factory BuddyIntent.batch({
    required BuddyBatchKind kind,
    required String language,
    required String script,
    required String? name,

    /// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
    required List<BuddyFoodItem> ingredients,

    /// The cooked weight the user stated.
    required BuddyAmount? cookedWeight,
    required BuddyBatchPath? path,

    /// The portion eaten now (AI-101).
    required BuddyPortion? eatenNow,

    /// Literal time phrase as the user said it (B08); the app resolves it.
    required String? timeHint,

    /// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
    required String? slotHint,

    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,
  }) = BuddyIntentBatch;

  @FreezedUnionValue('batchPortion')
  const factory BuddyIntent.batchPortion({
    required BuddyBatchPortionKind kind,
    required String language,
    required String script,

    /// A request openBatches ID.
    required String batchId,

    /// The portion eaten; null when rest is true.
    required BuddyPortion? portion,

    /// The user ate the rest of the batch.
    required bool rest,

    /// Literal time phrase as the user said it (B08); the app resolves it.
    required String? timeHint,

    /// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
    required String? slotHint,

    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,
  }) = BuddyIntentBatchPortion;

  @FreezedUnionValue('batchClose')
  const factory BuddyIntent.batchClose({
    required BuddyBatchCloseKind kind,
    required String language,
    required String script,

    /// A request openBatches ID.
    required String batchId,
  }) = BuddyIntentBatchClose;

  @FreezedUnionValue('personalFoodCreate')
  const factory BuddyIntent.personalFoodCreate({
    required BuddyPersonalFoodCreateKind kind,
    required String language,
    required String script,
    required String name,
    required List<String> aliases,

    /// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
    required List<BuddyFoodItem> components,
    required BuddyStatedNutrients? stated,
  }) = BuddyIntentPersonalFoodCreate;

  @FreezedUnionValue('savedMealLog')
  const factory BuddyIntent.savedMealLog({
    required BuddySavedMealLogKind kind,
    required String language,
    required String script,

    /// A request savedMeals ID.
    required String savedMealId,

    /// Literal time phrase as the user said it (B08); the app resolves it.
    required String? timeHint,

    /// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
    required String? slotHint,

    /// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
    required String? dateHint,
    required BuddyShare? share,
  }) = BuddyIntentSavedMealLog;

  @FreezedUnionValue('savedMealCreate')
  const factory BuddyIntent.savedMealCreate({
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
  }) = BuddyIntentSavedMealCreate;

  const factory BuddyIntent.unrecognized() = BuddyIntentUnrecognized;

  factory BuddyIntent.fromJson(Map<String, Object?> json) =>
      _$BuddyIntentFromJson(json);
}
