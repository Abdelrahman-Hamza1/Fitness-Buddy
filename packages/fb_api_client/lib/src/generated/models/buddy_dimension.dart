// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_dimension_option.dart';

part 'buddy_dimension.freezed.dart';
part 'buddy_dimension.g.dart';

@Freezed()
abstract class BuddyDimension with _$BuddyDimension {
  const factory BuddyDimension({
    required String kind,
    required String? statedValue,
    required List<BuddyDimensionOption> options,
  }) = _BuddyDimension;

  factory BuddyDimension.fromJson(Map<String, Object?> json) =>
      _$BuddyDimensionFromJson(json);
}
