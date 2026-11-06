// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_turn_message.freezed.dart';
part 'buddy_turn_message.g.dart';

@Freezed()
abstract class BuddyTurnMessage with _$BuddyTurnMessage {
  const factory BuddyTurnMessage({
    required String text,

    /// Optional meal photo: a base64 JPEG, at most 1024 px on its long side. Never stored.
    required String? image,
  }) = _BuddyTurnMessage;

  factory BuddyTurnMessage.fromJson(Map<String, Object?> json) =>
      _$BuddyTurnMessageFromJson(json);
}
