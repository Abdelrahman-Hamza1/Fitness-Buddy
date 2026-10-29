// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_active_card_line.freezed.dart';
part 'buddy_active_card_line.g.dart';

@Freezed()
abstract class BuddyActiveCardLine with _$BuddyActiveCardLine {
  const factory BuddyActiveCardLine({
    /// At most 200 characters.
    required String name,

    /// Greater than 0, or null.
    required double? amount,

    /// A unit code: g, ml or a serving unit (piece, loaf, plate, glass, sandwich, disc, serving, can, cup, tbsp, tsp).
    required String? unitCode,

    /// A FoodState code: raw, cooked, dry, drained, fried, as_sold.
    required String? state,
  }) = _BuddyActiveCardLine;

  factory BuddyActiveCardLine.fromJson(Map<String, Object?> json) =>
      _$BuddyActiveCardLineFromJson(json);
}
