// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_amount.freezed.dart';
part 'buddy_amount.g.dart';

@Freezed()
abstract class BuddyAmount with _$BuddyAmount {
  const factory BuddyAmount({
    required double? value,
    required String? unit,
    required bool explicit,
  }) = _BuddyAmount;

  factory BuddyAmount.fromJson(Map<String, Object?> json) =>
      _$BuddyAmountFromJson(json);
}
