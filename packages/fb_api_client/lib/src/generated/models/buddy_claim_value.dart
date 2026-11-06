// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_claim_unit.dart';
import 'buddy_query_metric.dart';
import 'buddy_query_op.dart';

part 'buddy_claim_value.freezed.dart';
part 'buddy_claim_value.g.dart';

/// A number (or, for exerciseLastDate, a date) computed on the device, in canonical units. The server assigns the claim ID and renders value, unit and a code-made label from metric, operation and the plan's period (06 §4, §7).
@Freezed()
abstract class BuddyClaimValue with _$BuddyClaimValue {
  const factory BuddyClaimValue({
    required BuddyQueryMetric metric,
    required BuddyQueryOp operation,
    required double? value,
    required String? date,
    required BuddyClaimUnit unit,

    /// For op last: the session found (mapped to a handle).
    required String? workoutId,
    required String? exerciseRef,
    required String? muscleGroup,
  }) = _BuddyClaimValue;

  factory BuddyClaimValue.fromJson(Map<String, Object?> json) =>
      _$BuddyClaimValueFromJson(json);
}
