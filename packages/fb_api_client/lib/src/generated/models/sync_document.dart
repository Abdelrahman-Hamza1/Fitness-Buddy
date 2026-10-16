// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_document.freezed.dart';
part 'sync_document.g.dart';

/// A stored version with a decimal sequence. History sequences are in a separate cursor space.
@Freezed()
abstract class SyncDocument with _$SyncDocument {
  const factory SyncDocument({
    required String entity,
    required String id,
    required int schemaVersion,
    required String hlc,
    required String deviceId,
    required DateTime? deletedAt,
    required Map<String, dynamic> payload,
    required String serverSeq,
  }) = _SyncDocument;

  factory SyncDocument.fromJson(Map<String, Object?> json) =>
      _$SyncDocumentFromJson(json);
}
