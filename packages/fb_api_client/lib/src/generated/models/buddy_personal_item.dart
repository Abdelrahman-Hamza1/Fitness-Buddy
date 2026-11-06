// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_nutrients_request.dart';
import 'buddy_personal_kind.dart';
import 'buddy_portion_facts.dart';
import 'buddy_serving.dart';

part 'buddy_personal_item.freezed.dart';
part 'buddy_personal_item.g.dart';

@Freezed()
abstract class BuddyPersonalItem with _$BuddyPersonalItem {
  const factory BuddyPersonalItem({
    required BuddyPersonalKind kind,

    /// The local row ID (a usual meal uses its representative row's ID). Mapped to a handle; never sent to the model.
    required String ref,
    required List<String> names,
    required List<String> aliases,
    required String? state,

    /// Nutrients per 100 g (personal foods, batches), or null.
    required BuddyNutrientsRequest? per100,
    required List<BuddyServing> servings,

    /// Named portions with their nutrients: a saved meal's whole meal, a batch's portion or remaining amount.
    required List<BuddyPortionFacts> portions,
  }) = _BuddyPersonalItem;

  factory BuddyPersonalItem.fromJson(Map<String, Object?> json) =>
      _$BuddyPersonalItemFromJson(json);
}
