// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_push_result.freezed.dart';
part 'sync_push_result.g.dart';

@Freezed()
abstract class SyncPushResult with _$SyncPushResult {
  const factory SyncPushResult({
    required String entity,
    required String id,
    required String hlc,
    required String status,
    required String? reason,
  }) = _SyncPushResult;

  factory SyncPushResult.fromJson(Map<String, Object?> json) =>
      _$SyncPushResultFromJson(json);
}
