// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_memory.freezed.dart';
part 'buddy_memory.g.dart';

@Freezed()
abstract class BuddyMemory with _$BuddyMemory {
  const factory BuddyMemory({
    /// Open string; the memoryKind codes are recommended: default, portion, alias, brand, nickname.
    required String kind,
    required String key,
    required String value,
  }) = _BuddyMemory;

  factory BuddyMemory.fromJson(Map<String, Object?> json) =>
      _$BuddyMemoryFromJson(json);
}
