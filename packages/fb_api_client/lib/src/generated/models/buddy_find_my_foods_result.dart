// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_find_my_foods_data.dart';
import 'buddy_find_my_foods_result_name.dart';
import 'buddy_phone_tool_error.dart';
import 'buddy_phone_tool_result.dart';

part 'buddy_find_my_foods_result.freezed.dart';
part 'buddy_find_my_foods_result.g.dart';

@Freezed()
abstract class BuddyFindMyFoodsResult with _$BuddyFindMyFoodsResult {
  const factory BuddyFindMyFoodsResult({
    required BuddyFindMyFoodsResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyFindMyFoodsData? data,
  }) = _BuddyFindMyFoodsResult;

  factory BuddyFindMyFoodsResult.fromJson(Map<String, Object?> json) =>
      _$BuddyFindMyFoodsResultFromJson(json);
}
