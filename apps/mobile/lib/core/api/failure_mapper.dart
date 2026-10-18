import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/problem_types.dart';
import 'package:fb_mobile/core/errors/failure.dart';

/// Maps API errors to [Failure]s (`09` §8, S06 plan D11).
///
/// A problem+json body is mapped by its catalogue `type` first
/// ([ProblemTypes]); an unknown type, or no problem body, falls back to the
/// HTTP status.
abstract final class FailureMapper {
  /// The failure for a [DioException] from the API client.
  static Failure fromDio(DioException error) => switch (error.type) {
    DioExceptionType.connectionError => const OfflineFailure(),
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const TimeoutFailure(),
    DioExceptionType.badResponse => switch (error.response) {
      final response? => fromResponse(response),
      null => const UnexpectedFailure(),
    },
    DioExceptionType.cancel ||
    DioExceptionType.badCertificate ||
    DioExceptionType.unknown => const UnexpectedFailure(),
  };

  /// The failure for an error [response] (status 4xx/5xx).
  static Failure fromResponse(Response<Object?> response) {
    final status = response.statusCode ?? 0;
    final body = response.data;
    final problemType = _problemType(body);
    if (problemType != null) {
      final byType = _byType(problemType, response, body);
      if (byType != null) return byType;
    }
    return _byStatus(status, response);
  }

  static Failure? _byType(
    String type,
    Response<Object?> response,
    Object? body,
  ) => switch (type) {
    ProblemTypes.unauthorized => const UnauthorizedFailure(),
    ProblemTypes.forbidden => const ForbiddenFailure(),
    ProblemTypes.identityConflict => const ConflictFailure(),
    ProblemTypes.validationFailed => InvalidInputFailure(
      fieldErrors: _fieldErrors(body),
    ),
    ProblemTypes.rateLimited => RateLimitedFailure(
      retryAfter: _retryAfter(response),
    ),
    ProblemTypes.versionConflict => const ConflictFailure(),
    ProblemTypes.upgradeRequired => const UpgradeRequiredFailure(),
    _ => null,
  };

  static Failure _byStatus(int status, Response<Object?> response) =>
      switch (status) {
        400 => const InvalidInputFailure(),
        401 => const UnauthorizedFailure(),
        403 => const ForbiddenFailure(),
        404 => const NotFoundFailure(),
        409 || 412 => const ConflictFailure(),
        426 => const UpgradeRequiredFailure(),
        429 => RateLimitedFailure(retryAfter: _retryAfter(response)),
        >= 500 && < 600 => ServerFailure(status),
        _ => const UnexpectedFailure(),
      };

  /// The problem `type`, when [body] is a problem details object.
  static String? _problemType(Object? body) {
    if (body is! Map<String, Object?>) return null;
    try {
      return ProblemDetails.fromJson(body).type;
      // A body that isn't a valid problem (wrong member types) is mapped by
      // status; json_serializable reports it as a TypeError.
      // ignore: avoid_catching_errors
    } on TypeError {
      return null;
    }
  }

  /// The `errors` extension of a validation problem: field → messages.
  /// Malformed entries are skipped.
  static Map<String, List<String>> _fieldErrors(Object? body) {
    if (body is! Map<String, Object?>) return const {};
    final errors = body['errors'];
    if (errors is! Map<String, Object?>) return const {};
    return {
      for (final MapEntry(:key, :value) in errors.entries)
        if (value is List<Object?>) key: value.whereType<String>().toList(),
    };
  }

  /// `Retry-After` in seconds (the HTTP-date form is not used by our API).
  static Duration? _retryAfter(Response<Object?> response) {
    final seconds = int.tryParse(response.headers.value('retry-after') ?? '');
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }
}
