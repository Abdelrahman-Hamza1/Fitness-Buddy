// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'intent.dart';

part 'unknown_intent.freezed.dart';
part 'unknown_intent.g.dart';

@Freezed()
abstract class UnknownIntent with _$UnknownIntent {
  const factory UnknownIntent({required String kind, required String? reason}) =
      _UnknownIntent;

  factory UnknownIntent.fromJson(Map<String, Object?> json) =>
      _$UnknownIntentFromJson(json);
}
