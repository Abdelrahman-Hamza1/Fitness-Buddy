// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_query_filters.freezed.dart';
part 'buddy_query_filters.g.dart';

@Freezed()
abstract class BuddyQueryFilters with _$BuddyQueryFilters {
  const factory BuddyQueryFilters({
    required String? slot,
    required String? exerciseRef,

    /// A library muscle group (e.g. legs), for op last.
    required String? muscleGroup,

    /// null means the default: true for averages.
    required bool? completeDaysOnly,

    /// ISO weekdays 1 (Monday) to 7; empty means every day.
    required List<int> weekdays,
  }) = _BuddyQueryFilters;

  factory BuddyQueryFilters.fromJson(Map<String, Object?> json) =>
      _$BuddyQueryFiltersFromJson(json);
}
