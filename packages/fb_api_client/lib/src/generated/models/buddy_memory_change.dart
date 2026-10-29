// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_amount.dart';
import 'buddy_food_item.dart';
import 'buddy_intent.dart';
import 'buddy_memory_change_kind.dart';
import 'buddy_memory_dimension.dart';
import 'buddy_memory_kind.dart';
import 'buddy_memory_operation.dart';

part 'buddy_memory_change.freezed.dart';
part 'buddy_memory_change.g.dart';

/// An explicit memory statement (AI-055). The app confirms it; the server never applies defaults. Forget and overwrite match local memory on memoryKind plus food.match.key (or its yield group); the normalized subject matches exactly only for alias, brand and nickname; anything else is clarified. memoryKind portion (a usual amount) differs from dimension portion (a default size variant of memoryKind default). A specific cooking-fat food isn't carried yet.
@Freezed()
abstract class BuddyMemoryChange with _$BuddyMemoryChange {
  const factory BuddyMemoryChange({
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
  }) = _BuddyMemoryChange;

  factory BuddyMemoryChange.fromJson(Map<String, Object?> json) =>
      _$BuddyMemoryChangeFromJson(json);
}
