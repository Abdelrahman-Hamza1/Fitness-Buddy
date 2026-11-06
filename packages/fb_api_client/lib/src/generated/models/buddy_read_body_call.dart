// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_call.dart';
import 'buddy_read_body_args.dart';
import 'buddy_read_body_call_name.dart';

part 'buddy_read_body_call.freezed.dart';
part 'buddy_read_body_call.g.dart';

/// Weight and measurements: raw values over at most 31 days (≤ 31 rows); a weight trend over at most 365 days as aggregates.
@Freezed()
abstract class BuddyReadBodyCall with _$BuddyReadBodyCall {
  const factory BuddyReadBodyCall({
    required BuddyReadBodyCallName name,
    required String callId,
    required BuddyReadBodyArgs args,
  }) = _BuddyReadBodyCall;

  factory BuddyReadBodyCall.fromJson(Map<String, Object?> json) =>
      _$BuddyReadBodyCallFromJson(json);
}
