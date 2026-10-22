// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_intent.dart';
import 'buddy_out_of_scope_kind.dart';

part 'buddy_out_of_scope.freezed.dart';
part 'buddy_out_of_scope.g.dart';

@Freezed()
abstract class BuddyOutOfScope with _$BuddyOutOfScope {
  const factory BuddyOutOfScope({
    required BuddyOutOfScopeKind kind,
    required String language,
    required String script,
    required String reason,
  }) = _BuddyOutOfScope;

  factory BuddyOutOfScope.fromJson(Map<String, Object?> json) =>
      _$BuddyOutOfScopeFromJson(json);
}
