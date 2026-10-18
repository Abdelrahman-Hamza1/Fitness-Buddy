// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'email_verify_request.freezed.dart';
part 'email_verify_request.g.dart';

@Freezed()
abstract class EmailVerifyRequest with _$EmailVerifyRequest {
  const factory EmailVerifyRequest({
    required String challengeId,
    required String code,
  }) = _EmailVerifyRequest;

  factory EmailVerifyRequest.fromJson(Map<String, Object?> json) =>
      _$EmailVerifyRequestFromJson(json);
}
