// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_body_unit.dart';

part 'buddy_body_value.freezed.dart';
part 'buddy_body_value.g.dart';

@Freezed()
abstract class BuddyBodyValue with _$BuddyBodyValue {
  const factory BuddyBodyValue({
    required String date,

    /// weight, a measurement kind, or a custom measurement name.
    required String metric,
    required double value,
    required BuddyBodyUnit unit,
  }) = _BuddyBodyValue;

  factory BuddyBodyValue.fromJson(Map<String, Object?> json) =>
      _$BuddyBodyValueFromJson(json);
}
