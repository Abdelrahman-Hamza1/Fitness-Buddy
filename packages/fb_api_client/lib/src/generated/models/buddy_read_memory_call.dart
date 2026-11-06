// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_call.dart';
import 'buddy_read_memory_args.dart';
import 'buddy_read_memory_call_name.dart';

part 'buddy_read_memory_call.freezed.dart';
part 'buddy_read_memory_call.g.dart';

/// Memory items (≤ 30).
@Freezed()
abstract class BuddyReadMemoryCall with _$BuddyReadMemoryCall {
  const factory BuddyReadMemoryCall({
    required BuddyReadMemoryCallName name,
    required String callId,
    required BuddyReadMemoryArgs args,
  }) = _BuddyReadMemoryCall;

  factory BuddyReadMemoryCall.fromJson(Map<String, Object?> json) =>
      _$BuddyReadMemoryCallFromJson(json);
}
