// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'link_identity_request.freezed.dart';
part 'link_identity_request.g.dart';

@Freezed()
abstract class LinkIdentityRequest with _$LinkIdentityRequest {
  const factory LinkIdentityRequest({
    required String? idToken,
    required String? challengeId,
    required String? code,
  }) = _LinkIdentityRequest;

  factory LinkIdentityRequest.fromJson(Map<String, Object?> json) =>
      _$LinkIdentityRequestFromJson(json);
}
