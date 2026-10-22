// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_intent.dart';

part 'buddy_interpretation.freezed.dart';
part 'buddy_interpretation.g.dart';

@Freezed()
abstract class BuddyInterpretation with _$BuddyInterpretation {
  const factory BuddyInterpretation({
    required String promptVersion,
    required String model,
    required List<BuddyIntent> intents,
  }) = _BuddyInterpretation;

  factory BuddyInterpretation.fromJson(Map<String, Object?> json) =>
      _$BuddyInterpretationFromJson(json);
}
