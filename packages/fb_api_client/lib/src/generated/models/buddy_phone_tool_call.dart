// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_find_my_foods_args.dart';
import 'buddy_find_my_foods_call.dart';
import 'buddy_find_my_foods_call_name.dart';
import 'buddy_query_data_call.dart';
import 'buddy_query_data_call_name.dart';
import 'buddy_query_plan.dart';
import 'buddy_read_body_args.dart';
import 'buddy_read_body_call.dart';
import 'buddy_read_body_call_name.dart';
import 'buddy_read_diary_args.dart';
import 'buddy_read_diary_call.dart';
import 'buddy_read_diary_call_name.dart';
import 'buddy_read_memory_args.dart';
import 'buddy_read_memory_call.dart';
import 'buddy_read_memory_call_name.dart';
import 'buddy_read_workouts_args.dart';
import 'buddy_read_workouts_call.dart';
import 'buddy_read_workouts_call_name.dart';

part 'buddy_phone_tool_call.freezed.dart';
part 'buddy_phone_tool_call.g.dart';

/// One phone-tool call of a phoneTools event, discriminated by the tool name. The phone enforces each tool's scope whatever the arguments say (06 §4.2).
@Freezed(unionKey: 'name', fallbackUnion: 'unrecognized')
sealed class BuddyPhoneToolCall with _$BuddyPhoneToolCall {
  @FreezedUnionValue('findMyFoods')
  const factory BuddyPhoneToolCall.findMyFoods({
    required BuddyFindMyFoodsCallName name,
    required String callId,
    required BuddyFindMyFoodsArgs args,
  }) = BuddyPhoneToolCallFindMyFoods;

  @FreezedUnionValue('readDiary')
  const factory BuddyPhoneToolCall.readDiary({
    required BuddyReadDiaryCallName name,
    required String callId,
    required BuddyReadDiaryArgs args,
  }) = BuddyPhoneToolCallReadDiary;

  @FreezedUnionValue('readBody')
  const factory BuddyPhoneToolCall.readBody({
    required BuddyReadBodyCallName name,
    required String callId,
    required BuddyReadBodyArgs args,
  }) = BuddyPhoneToolCallReadBody;

  @FreezedUnionValue('readWorkouts')
  const factory BuddyPhoneToolCall.readWorkouts({
    required BuddyReadWorkoutsCallName name,
    required String callId,
    required BuddyReadWorkoutsArgs args,
  }) = BuddyPhoneToolCallReadWorkouts;

  @FreezedUnionValue('readMemory')
  const factory BuddyPhoneToolCall.readMemory({
    required BuddyReadMemoryCallName name,
    required String callId,
    required BuddyReadMemoryArgs args,
  }) = BuddyPhoneToolCallReadMemory;

  @FreezedUnionValue('queryData')
  const factory BuddyPhoneToolCall.queryData({
    required BuddyQueryDataCallName name,
    required String callId,
    required BuddyQueryPlan args,
  }) = BuddyPhoneToolCallQueryData;

  const factory BuddyPhoneToolCall.unrecognized() =
      BuddyPhoneToolCallUnrecognized;

  factory BuddyPhoneToolCall.fromJson(Map<String, Object?> json) =>
      _$BuddyPhoneToolCallFromJson(json);
}
