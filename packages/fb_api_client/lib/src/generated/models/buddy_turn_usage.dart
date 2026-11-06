// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_turn_usage.freezed.dart';
part 'buddy_turn_usage.g.dart';

@Freezed()
abstract class BuddyTurnUsage with _$BuddyTurnUsage {
  const factory BuddyTurnUsage({
    required int sends,
    required int inputTokens,
    required int outputTokens,
  }) = _BuddyTurnUsage;

  factory BuddyTurnUsage.fromJson(Map<String, Object?> json) =>
      _$BuddyTurnUsageFromJson(json);
}
