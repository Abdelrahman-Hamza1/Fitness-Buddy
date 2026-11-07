// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_label_confidence.dart';

part 'buddy_label_other.freezed.dart';
part 'buddy_label_other.g.dart';

@Freezed()
abstract class BuddyLabelOther with _$BuddyLabelOther {
  const factory BuddyLabelOther({
    required String name,
    required double value,
    required String unit,
    required BuddyLabelConfidence confidence,
  }) = _BuddyLabelOther;

  factory BuddyLabelOther.fromJson(Map<String, Object?> json) =>
      _$BuddyLabelOtherFromJson(json);
}
