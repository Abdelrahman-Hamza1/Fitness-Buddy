// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'sync_push_result.dart';

part 'sync_push_response.freezed.dart';
part 'sync_push_response.g.dart';

@Freezed()
abstract class SyncPushResponse with _$SyncPushResponse {
  const factory SyncPushResponse({
    required List<SyncPushResult> results,
    required DateTime serverTime,
    required String datasetId,
  }) = _SyncPushResponse;

  factory SyncPushResponse.fromJson(Map<String, Object?> json) =>
      _$SyncPushResponseFromJson(json);
}
