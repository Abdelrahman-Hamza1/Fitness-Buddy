// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'email_link_start_request.freezed.dart';
part 'email_link_start_request.g.dart';

@Freezed()
abstract class EmailLinkStartRequest with _$EmailLinkStartRequest {
  const factory EmailLinkStartRequest({required String email}) =
      _EmailLinkStartRequest;

  factory EmailLinkStartRequest.fromJson(Map<String, Object?> json) =>
      _$EmailLinkStartRequestFromJson(json);
}
