// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'validation_problem_details.freezed.dart';
part 'validation_problem_details.g.dart';

/// The problem details of a `400 /errors/validation-failed`: the ProblemDetails members plus a required `errors` map.
@Freezed()
abstract class ValidationProblemDetails with _$ValidationProblemDetails {
  const factory ValidationProblemDetails({
    /// Always `/errors/validation-failed`.
    required String type,

    /// Short, human-readable summary of the problem type (English, not for display as-is).
    required String title,

    /// Always 400.
    required int status,

    /// Field (camelCase JSON path such as `items[0].qty`, or a lowercase header name such as `x-app-version`) → messages. Empty when the request could not be read (malformed JSON, wrong type, missing member).
    required Map<String, List<String>> errors,

    /// Human-readable explanation of this occurrence (English, never user content).
    String? detail,

    /// Identifies this occurrence (for example the request path).
    String? instance,

    /// W3C trace id of the request (32 lowercase hex), the same value as the `X-Request-Id` response header. Quote it when reporting a problem.
    String? traceId,
  }) = _ValidationProblemDetails;

  factory ValidationProblemDetails.fromJson(Map<String, Object?> json) =>
      _$ValidationProblemDetailsFromJson(json);
}
