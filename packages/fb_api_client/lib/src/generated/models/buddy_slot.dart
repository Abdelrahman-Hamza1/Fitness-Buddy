// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_slot.freezed.dart';
part 'buddy_slot.g.dart';

@Freezed()
abstract class BuddySlot with _$BuddySlot {
  const factory BuddySlot({
    required String id,
    required String name,
    required String? window,
  }) = _BuddySlot;

  factory BuddySlot.fromJson(Map<String, Object?> json) =>
      _$BuddySlotFromJson(json);
}
