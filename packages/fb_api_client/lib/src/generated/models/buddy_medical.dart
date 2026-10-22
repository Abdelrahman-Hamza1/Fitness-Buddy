// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_intent.dart';
import 'buddy_medical_kind.dart';

part 'buddy_medical.freezed.dart';
part 'buddy_medical.g.dart';

@Freezed()
abstract class BuddyMedical with _$BuddyMedical {
  const factory BuddyMedical({
    required BuddyMedicalKind kind,
    required String language,
    required String script,
  }) = _BuddyMedical;

  factory BuddyMedical.fromJson(Map<String, Object?> json) =>
      _$BuddyMedicalFromJson(json);
}
