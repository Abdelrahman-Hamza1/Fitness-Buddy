// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'id.dart';
import 'instant.dart';
import 'local_date.dart';

part 'interpret_request.freezed.dart';
part 'interpret_request.g.dart';

@Freezed()
abstract class InterpretRequest with _$InterpretRequest {
  const factory InterpretRequest({
    required Id messageId,
    required String text,
    required Instant sentAt,
    required LocalDate localDate,
  }) = _InterpretRequest;

  factory InterpretRequest.fromJson(Map<String, Object?> json) =>
      _$InterpretRequestFromJson(json);
}
