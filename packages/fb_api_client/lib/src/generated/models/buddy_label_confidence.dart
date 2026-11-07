// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// How sure the read is; the review screen highlights medium and low (FD-041). A null value is low.
@JsonEnum()
enum BuddyLabelConfidence {
  @JsonValue('high')
  high('high'),
  @JsonValue('medium')
  medium('medium'),
  @JsonValue('low')
  low('low'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BuddyLabelConfidence(this.json);

  factory BuddyLabelConfidence.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BuddyLabelConfidence> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
