// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'sync_document.dart';

part 'sync_page.freezed.dart';
part 'sync_page.g.dart';

@Freezed()
abstract class SyncPage with _$SyncPage {
  const factory SyncPage({
    required List<SyncDocument> changes,
    required String nextCursor,
  }) = _SyncPage;

  factory SyncPage.fromJson(Map<String, Object?> json) =>
      _$SyncPageFromJson(json);
}
