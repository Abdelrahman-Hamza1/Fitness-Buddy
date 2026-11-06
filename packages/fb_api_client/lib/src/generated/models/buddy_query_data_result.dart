// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_phone_tool_error.dart';
import 'buddy_phone_tool_result.dart';
import 'buddy_query_data_result_name.dart';
import 'buddy_query_result_data.dart';

part 'buddy_query_data_result.freezed.dart';
part 'buddy_query_data_result.g.dart';

@Freezed()
abstract class BuddyQueryDataResult with _$BuddyQueryDataResult {
  const factory BuddyQueryDataResult({
    required BuddyQueryDataResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyQueryResultData? data,
  }) = _BuddyQueryDataResult;

  factory BuddyQueryDataResult.fromJson(Map<String, Object?> json) =>
      _$BuddyQueryDataResultFromJson(json);
}
