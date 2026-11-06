// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_card_revision.freezed.dart';
part 'buddy_card_revision.g.dart';

@Freezed()
abstract class BuddyCardRevision with _$BuddyCardRevision {
  const factory BuddyCardRevision({
    required String proposalId,
    required int expectedRevision,
  }) = _BuddyCardRevision;

  factory BuddyCardRevision.fromJson(Map<String, Object?> json) =>
      _$BuddyCardRevisionFromJson(json);
}
