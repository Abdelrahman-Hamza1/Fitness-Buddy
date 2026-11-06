// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_open_card.freezed.dart';
part 'buddy_open_card.g.dart';

@Freezed()
abstract class BuddyOpenCard with _$BuddyOpenCard {
  const factory BuddyOpenCard({
    required String kind,
    required String proposalId,
    required int revision,
    required String summary,
  }) = _BuddyOpenCard;

  factory BuddyOpenCard.fromJson(Map<String, Object?> json) =>
      _$BuddyOpenCardFromJson(json);
}
