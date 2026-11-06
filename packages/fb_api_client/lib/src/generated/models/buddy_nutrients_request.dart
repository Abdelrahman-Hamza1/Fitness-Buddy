// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_nutrients_request.freezed.dart';
part 'buddy_nutrients_request.g.dart';

/// Nutrients sent by the phone (same members as BuddyNutrients).
@Freezed()
abstract class BuddyNutrientsRequest with _$BuddyNutrientsRequest {
  const factory BuddyNutrientsRequest({
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required double fiberG,
  }) = _BuddyNutrientsRequest;

  factory BuddyNutrientsRequest.fromJson(Map<String, Object?> json) =>
      _$BuddyNutrientsRequestFromJson(json);
}
