// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_turn_reference.freezed.dart';
part 'buddy_turn_reference.g.dart';

@Freezed()
abstract class BuddyTurnReference with _$BuddyTurnReference {
  const factory BuddyTurnReference({required String turnId}) =
      _BuddyTurnReference;

  factory BuddyTurnReference.fromJson(Map<String, Object?> json) =>
      _$BuddyTurnReferenceFromJson(json);
}
