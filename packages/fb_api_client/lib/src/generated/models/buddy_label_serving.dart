// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_label_confidence.dart';

part 'buddy_label_serving.freezed.dart';
part 'buddy_label_serving.g.dart';

/// The serving as printed ("1 cup (240 ml)"): amount and unit as written, grams or millilitres when stated, the printed label.
@Freezed()
abstract class BuddyLabelServing with _$BuddyLabelServing {
  const factory BuddyLabelServing({
    required double? amount,
    required String? unit,
    required double? g,
    required double? ml,
    required String? label,
    required BuddyLabelConfidence confidence,
  }) = _BuddyLabelServing;

  factory BuddyLabelServing.fromJson(Map<String, Object?> json) =>
      _$BuddyLabelServingFromJson(json);
}
