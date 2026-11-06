// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_intent.dart';
import 'buddy_suggestion_kind.dart';
import 'buddy_suggestion_option.dart';

part 'buddy_suggestion.freezed.dart';
part 'buddy_suggestion.g.dart';

/// 2–4 food options (A68, AI-120/121); a tap creates a food card, the app drops options that don't fit.
@Freezed()
abstract class BuddySuggestion with _$BuddySuggestion {
  const factory BuddySuggestion({
    required BuddySuggestionKind kind,
    required String language,
    required String script,
    required List<BuddySuggestionOption> options,
  }) = _BuddySuggestion;

  factory BuddySuggestion.fromJson(Map<String, Object?> json) =>
      _$BuddySuggestionFromJson(json);
}
