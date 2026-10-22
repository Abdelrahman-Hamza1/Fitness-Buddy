// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_nutrients.dart';

part 'buddy_range.freezed.dart';
part 'buddy_range.g.dart';

@Freezed()
abstract class BuddyRange with _$BuddyRange {
  const factory BuddyRange({
    required BuddyNutrients low,
    required BuddyNutrients high,
  }) = _BuddyRange;

  factory BuddyRange.fromJson(Map<String, Object?> json) =>
      _$BuddyRangeFromJson(json);
}
