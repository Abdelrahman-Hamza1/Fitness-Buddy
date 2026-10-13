// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'problem_details.freezed.dart';
part 'problem_details.g.dart';

@Freezed()
abstract class ProblemDetails with _$ProblemDetails {
  const factory ProblemDetails({
    required String type,
    required String title,
    required int status,
  }) = _ProblemDetails;

  factory ProblemDetails.fromJson(Map<String, Object?> json) =>
      _$ProblemDetailsFromJson(json);
}
