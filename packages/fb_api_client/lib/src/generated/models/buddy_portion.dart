// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_amount.dart';
import 'buddy_share.dart';

part 'buddy_portion.freezed.dart';
part 'buddy_portion.g.dart';

/// At least one member is non-null: grams, plates, or a share. share.fraction is a fraction of the whole batch (for eatenNow and batchPortion).
@Freezed()
abstract class BuddyPortion with _$BuddyPortion {
  const factory BuddyPortion({
    required BuddyAmount? amount,
    required BuddyShare? share,
  }) = _BuddyPortion;

  factory BuddyPortion.fromJson(Map<String, Object?> json) =>
      _$BuddyPortionFromJson(json);
}
