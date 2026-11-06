// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_nutrients_request.dart';

part 'buddy_portion_facts.freezed.dart';
part 'buddy_portion_facts.g.dart';

@Freezed()
abstract class BuddyPortionFacts with _$BuddyPortionFacts {
  const factory BuddyPortionFacts({
    required String label,
    required double? g,
    required BuddyNutrientsRequest nutrients,
  }) = _BuddyPortionFacts;

  factory BuddyPortionFacts.fromJson(Map<String, Object?> json) =>
      _$BuddyPortionFactsFromJson(json);
}
