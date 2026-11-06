// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_find_my_foods_data.dart';
import 'buddy_find_my_foods_result.dart';
import 'buddy_find_my_foods_result_name.dart';
import 'buddy_phone_tool_error.dart';
import 'buddy_query_data_result.dart';
import 'buddy_query_data_result_name.dart';
import 'buddy_query_result_data.dart';
import 'buddy_read_body_data.dart';
import 'buddy_read_body_result.dart';
import 'buddy_read_body_result_name.dart';
import 'buddy_read_diary_data.dart';
import 'buddy_read_diary_result.dart';
import 'buddy_read_diary_result_name.dart';
import 'buddy_read_memory_data.dart';
import 'buddy_read_memory_result.dart';
import 'buddy_read_memory_result_name.dart';
import 'buddy_read_workouts_data.dart';
import 'buddy_read_workouts_result.dart';
import 'buddy_read_workouts_result_name.dart';

part 'buddy_phone_tool_result.freezed.dart';
part 'buddy_phone_tool_result.g.dart';

/// One phone-tool result, discriminated by the tool name. ok false carries an error code and null data.
@Freezed(unionKey: 'name', fallbackUnion: 'unrecognized')
sealed class BuddyPhoneToolResult with _$BuddyPhoneToolResult {
  @FreezedUnionValue('findMyFoods')
  const factory BuddyPhoneToolResult.findMyFoods({
    required BuddyFindMyFoodsResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyFindMyFoodsData? data,
  }) = BuddyPhoneToolResultFindMyFoods;

  @FreezedUnionValue('readDiary')
  const factory BuddyPhoneToolResult.readDiary({
    required BuddyReadDiaryResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyReadDiaryData? data,
  }) = BuddyPhoneToolResultReadDiary;

  @FreezedUnionValue('readBody')
  const factory BuddyPhoneToolResult.readBody({
    required BuddyReadBodyResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyReadBodyData? data,
  }) = BuddyPhoneToolResultReadBody;

  @FreezedUnionValue('readWorkouts')
  const factory BuddyPhoneToolResult.readWorkouts({
    required BuddyReadWorkoutsResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyReadWorkoutsData? data,
  }) = BuddyPhoneToolResultReadWorkouts;

  @FreezedUnionValue('readMemory')
  const factory BuddyPhoneToolResult.readMemory({
    required BuddyReadMemoryResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyReadMemoryData? data,
  }) = BuddyPhoneToolResultReadMemory;

  @FreezedUnionValue('queryData')
  const factory BuddyPhoneToolResult.queryData({
    required BuddyQueryDataResultName name,
    required String callId,
    required bool ok,
    required BuddyPhoneToolError? error,
    required BuddyQueryResultData? data,
  }) = BuddyPhoneToolResultQueryData;

  const factory BuddyPhoneToolResult.unrecognized() =
      BuddyPhoneToolResultUnrecognized;

  factory BuddyPhoneToolResult.fromJson(Map<String, Object?> json) =>
      _$BuddyPhoneToolResultFromJson(json);
}
