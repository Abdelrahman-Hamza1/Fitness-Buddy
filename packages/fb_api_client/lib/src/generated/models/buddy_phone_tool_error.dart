// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// budgetExceeded: the turn's disclosure budget (120 rows, 48 KiB across all phone results) is spent; unsupportedPlan: the QueryPlan isn't a valid combination; invalidArgs; unavailable. Additive.
@JsonEnum()
enum BuddyPhoneToolError {
  @JsonValue('budgetExceeded')
  budgetExceeded('budgetExceeded'),
  @JsonValue('unsupportedPlan')
  unsupportedPlan('unsupportedPlan'),
  @JsonValue('invalidArgs')
  invalidArgs('invalidArgs'),
  @JsonValue('unavailable')
  unavailable('unavailable'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BuddyPhoneToolError(this.json);

  factory BuddyPhoneToolError.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BuddyPhoneToolError> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
