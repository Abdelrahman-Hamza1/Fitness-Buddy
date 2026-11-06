// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum()
enum BuddyPeriodKind {
  @JsonValue('today')
  today('today'),
  @JsonValue('yesterday')
  yesterday('yesterday'),
  @JsonValue('thisWeek')
  thisWeek('thisWeek'),
  @JsonValue('lastWeek')
  lastWeek('lastWeek'),
  @JsonValue('thisMonth')
  thisMonth('thisMonth'),
  @JsonValue('lastMonth')
  lastMonth('lastMonth'),
  @JsonValue('lastNDays')
  lastNDays('lastNDays'),
  @JsonValue('since')
  since('since'),
  @JsonValue('range')
  range('range'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BuddyPeriodKind(this.json);

  factory BuddyPeriodKind.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BuddyPeriodKind> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
