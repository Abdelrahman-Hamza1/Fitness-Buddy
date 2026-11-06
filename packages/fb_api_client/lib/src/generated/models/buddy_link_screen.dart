// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum BuddyLinkScreen {
  @JsonValue('diary')
  diary('diary'),
  @JsonValue('weightGraph')
  weightGraph('weightGraph'),
  @JsonValue('progress')
  progress('progress'),
  @JsonValue('exercise')
  exercise('exercise'),
  @JsonValue('workout')
  workout('workout'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BuddyLinkScreen(this.json);

  factory BuddyLinkScreen.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BuddyLinkScreen> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
