// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum BuddyMemoryKind {
  /// The name has been replaced because it contains a keyword. Original name: `default`.
  @JsonValue('default')
  valueDefault('default'),
  @JsonValue('portion')
  portion('portion'),
  @JsonValue('alias')
  alias('alias'),
  @JsonValue('brand')
  brand('brand'),
  @JsonValue('nickname')
  nickname('nickname'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BuddyMemoryKind(this.json);

  factory BuddyMemoryKind.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BuddyMemoryKind> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
