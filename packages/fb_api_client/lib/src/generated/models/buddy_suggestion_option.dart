// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_food_item.dart';

part 'buddy_suggestion_option.freezed.dart';
part 'buddy_suggestion_option.g.dart';

@Freezed()
abstract class BuddySuggestionOption with _$BuddySuggestionOption {
  const factory BuddySuggestionOption({
    required String label,
    required String? slotHint,
    required List<BuddyFoodItem> items,
  }) = _BuddySuggestionOption;

  factory BuddySuggestionOption.fromJson(Map<String, Object?> json) =>
      _$BuddySuggestionOptionFromJson(json);
}
