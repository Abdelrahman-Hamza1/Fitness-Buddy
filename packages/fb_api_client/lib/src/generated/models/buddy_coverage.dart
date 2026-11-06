// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_coverage.freezed.dart';
part 'buddy_coverage.g.dart';

@Freezed()
abstract class BuddyCoverage with _$BuddyCoverage {
  const factory BuddyCoverage({required int days, required int loggedDays}) =
      _BuddyCoverage;

  factory BuddyCoverage.fromJson(Map<String, Object?> json) =>
      _$BuddyCoverageFromJson(json);
}
