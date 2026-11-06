// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_find_my_foods_args.dart';
import 'buddy_find_my_foods_call_name.dart';
import 'buddy_phone_tool_call.dart';

part 'buddy_find_my_foods_call.freezed.dart';
part 'buddy_find_my_foods_call.g.dart';

/// Personal foods, saved meals, batches and usual meals by name or alias (≤ 20 matches).
@Freezed()
abstract class BuddyFindMyFoodsCall with _$BuddyFindMyFoodsCall {
  const factory BuddyFindMyFoodsCall({
    required BuddyFindMyFoodsCallName name,
    required String callId,
    required BuddyFindMyFoodsArgs args,
  }) = _BuddyFindMyFoodsCall;

  factory BuddyFindMyFoodsCall.fromJson(Map<String, Object?> json) =>
      _$BuddyFindMyFoodsCallFromJson(json);
}
