// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_label_confidence.dart';

part 'buddy_label_text.freezed.dart';
part 'buddy_label_text.g.dart';

/// A printed text, or null.
@Freezed()
abstract class BuddyLabelText with _$BuddyLabelText {
  const factory BuddyLabelText({
    required String? value,
    required BuddyLabelConfidence confidence,
  }) = _BuddyLabelText;

  factory BuddyLabelText.fromJson(Map<String, Object?> json) =>
      _$BuddyLabelTextFromJson(json);
}
