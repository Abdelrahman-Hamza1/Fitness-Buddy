// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'buddy_label_request.freezed.dart';
part 'buddy_label_request.g.dart';

/// A nutrition-label photo (FD-040): base64 JPEG, at most 1024 px on the long side. Never stored or logged.
@Freezed()
abstract class BuddyLabelRequest with _$BuddyLabelRequest {
  const factory BuddyLabelRequest({
    /// Base64 JPEG (no data: prefix).
    required String image,
  }) = _BuddyLabelRequest;

  factory BuddyLabelRequest.fromJson(Map<String, Object?> json) =>
      _$BuddyLabelRequestFromJson(json);
}
