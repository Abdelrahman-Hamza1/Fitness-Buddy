// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'google_sign_in_request.freezed.dart';
part 'google_sign_in_request.g.dart';

@Freezed()
abstract class GoogleSignInRequest with _$GoogleSignInRequest {
  const factory GoogleSignInRequest({required String idToken}) =
      _GoogleSignInRequest;

  factory GoogleSignInRequest.fromJson(Map<String, Object?> json) =>
      _$GoogleSignInRequestFromJson(json);
}
