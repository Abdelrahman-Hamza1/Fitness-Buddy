// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_active_card.dart';
import 'buddy_memory.dart';
import 'buddy_named_reference.dart';
import 'buddy_personal_food.dart';
import 'buddy_recent_entry.dart';

part 'buddy_context.freezed.dart';
part 'buddy_context.g.dart';

@Freezed()
abstract class BuddyContext with _$BuddyContext {
  const factory BuddyContext({
    required List<BuddyPersonalFood> personalFoods,
    required List<BuddyNamedReference> savedMeals,
    required List<BuddyNamedReference> openBatches,
    required List<BuddyMemory> memory,

    /// Ordered newest first; at most 30, about 3 days. Only date, slot and name are forwarded to the model.
    required List<BuddyRecentEntry> recentEntries,
    required List<BuddyNamedReference> customExercises,

    /// The open proposal card a follow-up refers to (AI-044). Requires activeProposal (else 400). Optional: older apps omit it; absent and null are the same. Its slot, time and line name/amount/unitCode/state are forwarded to the model.
    BuddyActiveCard? activeCard,
  }) = _BuddyContext;

  factory BuddyContext.fromJson(Map<String, Object?> json) =>
      _$BuddyContextFromJson(json);
}
