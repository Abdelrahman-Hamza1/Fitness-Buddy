// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_clarify_kind.dart';
import 'buddy_intent.dart';

part 'buddy_clarify.freezed.dart';
part 'buddy_clarify.g.dart';

@Freezed()
abstract class BuddyClarify with _$BuddyClarify {
  const factory BuddyClarify({
    required BuddyClarifyKind kind,
    required String language,
    required String script,
    required String reason,
  }) = _BuddyClarify;

  factory BuddyClarify.fromJson(Map<String, Object?> json) =>
      _$BuddyClarifyFromJson(json);
}
