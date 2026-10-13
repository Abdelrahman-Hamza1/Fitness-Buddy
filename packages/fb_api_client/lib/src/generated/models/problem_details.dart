// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'problem_details.freezed.dart';
part 'problem_details.g.dart';

/// RFC 9457 problem details. Members not listed here are extensions (for example `errors` on validation failures, S03) and clients must ignore the ones they don't know.
@Freezed()
abstract class ProblemDetails with _$ProblemDetails {
  const factory ProblemDetails({
    /// Identifies the kind of problem. Our own problems use a stable, relative reference `/errors/<kebab-slug>` from the catalogue in contracts/README.md (`/errors/validation-failed`, `/errors/rate-limited`, `/errors/version-conflict`, `/errors/upgrade-required`). It is an opaque string: clients compare it exactly and never dereference it, and an entry is never renamed or removed within an API version. Problems we don't map carry the framework's default (an RFC link or `about:blank`), so this is a free string, not an enum.
    required String type,

    /// Short, human-readable summary of the problem type (English, not for display as-is).
    required String title,

    /// The HTTP status code, repeated for convenience.
    required int status,

    /// Human-readable explanation of this occurrence (English, never user content).
    String? detail,

    /// Identifies this occurrence (for example the request path).
    String? instance,
  }) = _ProblemDetails;

  factory ProblemDetails.fromJson(Map<String, Object?> json) =>
      _$ProblemDetailsFromJson(json);
}
