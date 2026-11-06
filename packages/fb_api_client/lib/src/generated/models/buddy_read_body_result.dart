// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_error.dart';
import 'buddy_phone_tool_result.dart';
import 'buddy_read_body_data.dart';
import 'buddy_read_body_result_name.dart';

part 'buddy_read_body_result.freezed.dart';
part 'buddy_read_body_result.g.dart';

@Freezed()
abstract class BuddyReadBodyResult with _$BuddyReadBodyResult {
  const factory BuddyReadBodyResult({
    required BuddyReadBodyResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyReadBodyData? data,
  }) = _BuddyReadBodyResult;

  factory BuddyReadBodyResult.fromJson(Map<String, Object?> json) =>
      _$BuddyReadBodyResultFromJson(json);
}
