// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_trace_step.freezed.dart';
part 'buddy_trace_step.g.dart';

@Freezed()
abstract class BuddyTraceStep with _$BuddyTraceStep {
  const factory BuddyTraceStep({
    required String tool,
    required String args,
    required String resultSummary,
    required int ms,
    required int tokens,
    required double usd,
  }) = _BuddyTraceStep;

  factory BuddyTraceStep.fromJson(Map<String, Object?> json) =>
      _$BuddyTraceStepFromJson(json);
}
