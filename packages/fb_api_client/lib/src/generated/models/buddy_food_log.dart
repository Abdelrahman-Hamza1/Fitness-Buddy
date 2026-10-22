// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_food_item.dart';
import 'buddy_food_log_kind.dart';
import 'buddy_intent.dart';

part 'buddy_food_log.freezed.dart';
part 'buddy_food_log.g.dart';

@Freezed()
abstract class BuddyFoodLog with _$BuddyFoodLog {
  const factory BuddyFoodLog({
    required BuddyFoodLogKind kind,
    required String language,
    required String script,
    required String? timeHint,
    required String? slotHint,
    required String? dishGroup,
    required List<BuddyFoodItem> items,
  }) = _BuddyFoodLog;

  factory BuddyFoodLog.fromJson(Map<String, Object?> json) =>
      _$BuddyFoodLogFromJson(json);
}
