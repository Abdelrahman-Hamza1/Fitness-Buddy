// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'sync_change.dart';

part 'sync_push_request.freezed.dart';
part 'sync_push_request.g.dart';

@Freezed()
abstract class SyncPushRequest with _$SyncPushRequest {
  const factory SyncPushRequest({required List<SyncChange> changes}) =
      _SyncPushRequest;

  factory SyncPushRequest.fromJson(Map<String, Object?> json) =>
      _$SyncPushRequestFromJson(json);
}
