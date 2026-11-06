// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_memory.dart';

part 'buddy_read_memory_data.freezed.dart';
part 'buddy_read_memory_data.g.dart';

@Freezed()
abstract class BuddyReadMemoryData with _$BuddyReadMemoryData {
  const factory BuddyReadMemoryData({required List<BuddyMemory> items}) =
      _BuddyReadMemoryData;

  factory BuddyReadMemoryData.fromJson(Map<String, Object?> json) =>
      _$BuddyReadMemoryDataFromJson(json);
}
