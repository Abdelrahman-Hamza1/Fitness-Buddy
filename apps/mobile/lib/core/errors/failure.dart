/// Expected failures, as values (`09` §8, S06 plan D11).
///
/// The API client maps responses to them (`FailureMapper`). The UI maps each
/// one to plain-language copy and an action (UX-052); that copy comes with
/// the first screen that shows a failure. Unexpected errors are exceptions
/// and go to error reporting instead.
sealed class Failure {
  /// Creates a failure.
  const new();
}

/// The server couldn't be reached (no connection, DNS, refused).
final class OfflineFailure extends Failure {
  /// Creates the failure.
  const new();
}

/// The server didn't answer in time (connect, send or receive timeout).
final class TimeoutFailure extends Failure {
  /// Creates the failure.
  const new();
}

/// Too many requests (`/errors/rate-limited`, 429).
final class RateLimitedFailure extends Failure {
  /// Creates the failure; [retryAfter] from the `Retry-After` header.
  const new({this.retryAfter});

  /// How long to wait before retrying, when the server said so.
  final Duration? retryAfter;
}

/// The request was invalid (`/errors/validation-failed`, 400).
final class InvalidInputFailure extends Failure {
  /// Creates the failure with the server's [fieldErrors].
  const new({this.fieldErrors = const {}});

  /// Messages per request field (the problem's `errors` extension). English
  /// and for developers: never shown as-is, never logged (they may quote
  /// the input).
  final Map<String, List<String>> fieldErrors;
}

/// The resource changed since it was read (`/errors/version-conflict`).
final class ConflictFailure extends Failure {
  /// Creates the failure.
  const new();
}

/// The resource doesn't exist (404).
final class NotFoundFailure extends Failure {
  /// Creates the failure.
  const new();
}

/// The request needs a (fresh) sign-in (401).
final class UnauthorizedFailure extends Failure {
  /// Creates the failure.
  const new();
}

/// The signed-in account cannot perform this operation (403).
final class ForbiddenFailure extends Failure {
  /// Creates the failure.
  const new();
}

/// This app version is too old for the server (`/errors/upgrade-required`,
/// 426). The update gate shows the update screen (S06 plan D10).
final class UpgradeRequiredFailure extends Failure {
  /// Creates the failure.
  const new();
}

/// The server failed (5xx).
final class ServerFailure extends Failure {
  /// Creates the failure with the HTTP [status].
  const new(this.status);

  /// The HTTP status code.
  final int status;
}

/// Anything else: an unmapped status, a cancelled request, a bad
/// certificate, an error inside the client.
final class UnexpectedFailure extends Failure {
  /// Creates the failure.
  const new();
}
