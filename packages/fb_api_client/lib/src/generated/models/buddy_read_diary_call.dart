// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_call.dart';
import 'buddy_read_diary_args.dart';
import 'buddy_read_diary_call_name.dart';

part 'buddy_read_diary_call.freezed.dart';
part 'buddy_read_diary_call.g.dart';

/// Diary rows: a range of at most 31 days, at most 40 rows.
@Freezed()
abstract class BuddyReadDiaryCall with _$BuddyReadDiaryCall {
  const factory BuddyReadDiaryCall({
    required BuddyReadDiaryCallName name,
    required String callId,
    required BuddyReadDiaryArgs args,
  }) = _BuddyReadDiaryCall;

  factory BuddyReadDiaryCall.fromJson(Map<String, Object?> json) =>
      _$BuddyReadDiaryCallFromJson(json);
}
