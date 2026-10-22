// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_clarify.dart';
import 'buddy_clarify_kind.dart';
import 'buddy_food_item.dart';
import 'buddy_food_log.dart';
import 'buddy_food_log_kind.dart';
import 'buddy_medical.dart';
import 'buddy_medical_kind.dart';
import 'buddy_out_of_scope.dart';
import 'buddy_out_of_scope_kind.dart';
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
    required String? timeHint,
    required String? slotHint,
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
    required String? timeHint,
  }) = BuddyIntentWeighIn;

  const factory BuddyIntent.unrecognized() = BuddyIntentUnrecognized;

  factory BuddyIntent.fromJson(Map<String, Object?> json) =>
      _$BuddyIntentFromJson(json);
}
