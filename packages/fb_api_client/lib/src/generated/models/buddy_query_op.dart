// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum BuddyQueryOp {
  @JsonValue('total')
  total('total'),
  @JsonValue('average')
  average('average'),
  @JsonValue('remaining')
  remaining('remaining'),
  @JsonValue('latest')
  latest('latest'),
  @JsonValue('change')
  change('change'),
  @JsonValue('count')
  count('count'),
  @JsonValue('max')
  max('max'),
  @JsonValue('min')
  min('min'),
  @JsonValue('last')
  last('last'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BuddyQueryOp(this.json);

  factory BuddyQueryOp.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BuddyQueryOp> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
