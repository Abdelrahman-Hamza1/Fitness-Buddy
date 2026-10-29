// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'buddy_batch_close_kind.dart';
import 'buddy_intent.dart';

part 'buddy_batch_close.freezed.dart';
part 'buddy_batch_close.g.dart';

/// Closes an open batch without logging anything (the rest was thrown away, DY-044).
@Freezed()
abstract class BuddyBatchClose with _$BuddyBatchClose {
  const factory BuddyBatchClose({
    required BuddyBatchCloseKind kind,
    required String language,
    required String script,

    /// A request openBatches ID.
    required String batchId,
  }) = _BuddyBatchClose;

  factory BuddyBatchClose.fromJson(Map<String, Object?> json) =>
      _$BuddyBatchCloseFromJson(json);
}
