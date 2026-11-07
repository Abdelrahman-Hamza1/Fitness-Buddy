// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_label_basis.dart';
import 'buddy_label_nutrients.dart';
import 'buddy_label_other.dart';
import 'buddy_label_serving.dart';
import 'buddy_label_text.dart';

part 'buddy_label_extraction.freezed.dart';
part 'buddy_label_extraction.g.dart';

/// A label read (B26, FD-041): values on the label's own basis with a confidence per field. Review input only; the app converts to per 100 and saves nothing without the user.
@Freezed()
abstract class BuddyLabelExtraction with _$BuddyLabelExtraction {
  const factory BuddyLabelExtraction({
    /// False when no nutrition panel could be read; then basis and serving are null and every value is null.
    required bool found,
    required BuddyLabelBasis? basis,
    required BuddyLabelServing? serving,
    required BuddyLabelText name,
    required BuddyLabelNutrients nutrients,

    /// Other nutrients the label lists (vitamins, minerals…), as printed.
    required List<BuddyLabelOther> others,
  }) = _BuddyLabelExtraction;

  factory BuddyLabelExtraction.fromJson(Map<String, Object?> json) =>
      _$BuddyLabelExtractionFromJson(json);
}
