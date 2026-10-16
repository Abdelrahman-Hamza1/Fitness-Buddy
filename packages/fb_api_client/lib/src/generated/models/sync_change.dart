// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_change.freezed.dart';
part 'sync_change.g.dart';

/// An immutable client version; a non-null deletedAt marks a tombstone.
@Freezed()
abstract class SyncChange with _$SyncChange {
  const factory SyncChange({
    required String entity,
    required String id,
    required int schemaVersion,
    required String hlc,
    required String deviceId,
    required DateTime? deletedAt,
    required Map<String, dynamic> payload,
  }) = _SyncChange;

  factory SyncChange.fromJson(Map<String, Object?> json) =>
      _$SyncChangeFromJson(json);
}
