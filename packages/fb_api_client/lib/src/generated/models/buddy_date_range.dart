// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_date_range.freezed.dart';
part 'buddy_date_range.g.dart';

@Freezed()
abstract class BuddyDateRange with _$BuddyDateRange {
  const factory BuddyDateRange({required String from, required String to}) =
      _BuddyDateRange;

  factory BuddyDateRange.fromJson(Map<String, Object?> json) =>
      _$BuddyDateRangeFromJson(json);
}
