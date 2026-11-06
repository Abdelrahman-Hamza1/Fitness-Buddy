// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_call.dart';
import 'buddy_query_data_call_name.dart';
import 'buddy_query_plan.dart';

part 'buddy_query_data_call.freezed.dart';
part 'buddy_query_data_call.g.dart';

/// A question about the user's data as a QueryPlan, answered by the device's QueryEngine with aggregates only (periods ≤ 400 days).
@Freezed()
abstract class BuddyQueryDataCall with _$BuddyQueryDataCall {
  const factory BuddyQueryDataCall({
    required BuddyQueryDataCallName name,
    required String callId,
    required BuddyQueryPlan args,
  }) = _BuddyQueryDataCall;

  factory BuddyQueryDataCall.fromJson(Map<String, Object?> json) =>
      _$BuddyQueryDataCallFromJson(json);
}
