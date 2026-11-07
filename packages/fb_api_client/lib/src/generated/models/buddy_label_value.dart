// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_label_confidence.dart';

part 'buddy_label_value.freezed.dart';
part 'buddy_label_value.g.dart';

/// One value as read, or null when absent or unreadable.
@Freezed()
abstract class BuddyLabelValue with _$BuddyLabelValue {
  const factory BuddyLabelValue({
    required double? value,
    required BuddyLabelConfidence confidence,
  }) = _BuddyLabelValue;

  factory BuddyLabelValue.fromJson(Map<String, Object?> json) =>
      _$BuddyLabelValueFromJson(json);
}
