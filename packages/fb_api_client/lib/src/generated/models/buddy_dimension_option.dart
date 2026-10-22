// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_candidate.dart';

part 'buddy_dimension_option.freezed.dart';
part 'buddy_dimension_option.g.dart';

@Freezed()
abstract class BuddyDimensionOption with _$BuddyDimensionOption {
  const factory BuddyDimensionOption({
    required String value,
    required String? candidateKey,
    required double? amount,
    required String? unit,
    required BuddyCandidate? candidate,
  }) = _BuddyDimensionOption;

  factory BuddyDimensionOption.fromJson(Map<String, Object?> json) =>
      _$BuddyDimensionOptionFromJson(json);
}
