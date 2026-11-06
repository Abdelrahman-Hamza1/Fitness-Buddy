// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum BuddyClaimUnit {
  @JsonValue('kcal')
  kcal('kcal'),
  @JsonValue('g')
  g('g'),
  @JsonValue('kg')
  kg('kg'),
  @JsonValue('cm')
  cm('cm'),
  @JsonValue('percent')
  percent('percent'),
  @JsonValue('count')
  count('count'),
  @JsonValue('date')
  date('date'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BuddyClaimUnit(this.json);

  factory BuddyClaimUnit.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BuddyClaimUnit> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
