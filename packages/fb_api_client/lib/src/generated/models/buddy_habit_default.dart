// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_habit_default.freezed.dart';
part 'buddy_habit_default.g.dart';

@Freezed()
abstract class BuddyHabitDefault with _$BuddyHabitDefault {
  const factory BuddyHabitDefault({
    required String kind,
    required String subject,
    required String value,
  }) = _BuddyHabitDefault;

  factory BuddyHabitDefault.fromJson(Map<String, Object?> json) =>
      _$BuddyHabitDefaultFromJson(json);
}
