// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_error.dart';
import 'buddy_phone_tool_result.dart';
import 'buddy_unsupported_result_name.dart';

part 'buddy_unsupported_result.freezed.dart';
part 'buddy_unsupported_result.g.dart';

/// Any call the app doesn't know: ok false, error unsupported, no data. The server treats it as a tool error.
@Freezed()
abstract class BuddyUnsupportedResult with _$BuddyUnsupportedResult {
  const factory BuddyUnsupportedResult({
    required BuddyUnsupportedResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
  }) = _BuddyUnsupportedResult;

  factory BuddyUnsupportedResult.fromJson(Map<String, Object?> json) =>
      _$BuddyUnsupportedResultFromJson(json);
}
