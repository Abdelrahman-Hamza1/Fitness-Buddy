// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_context.dart';
import 'buddy_ramadan.dart';
import 'buddy_slot.dart';

part 'interpret_request.freezed.dart';
part 'interpret_request.g.dart';

@Freezed()
abstract class InterpretRequest with _$InterpretRequest {
  const factory InterpretRequest({
    required String requestId,
    required String text,
    required DateTime now,
    required int tzOffsetMin,
    required BuddyRamadan ramadan,
    required List<BuddySlot> slots,
    required String? activeProposal,
    required BuddyContext context,
  }) = _InterpretRequest;

  factory InterpretRequest.fromJson(Map<String, Object?> json) =>
      _$InterpretRequestFromJson(json);
}
