/// The problem `type` values of the API's error catalogue
/// (`contracts/README.md`, "Error type catalogue"; `09` §8).
///
/// Opaque strings, compared exactly and never dereferenced. They are
/// catalogue constants, not API types: the contract keeps `type` a free
/// string. A test keeps this list in sync with the README table.
abstract final class ProblemTypes {
  /// 400: the request is well-formed but invalid; carries `errors`.
  static const validationFailed = '/errors/validation-failed';

  /// 429: too many requests; comes with `Retry-After`.
  static const rateLimited = '/errors/rate-limited';

  /// 412: the resource changed since it was read (`If-Match` mismatch).
  static const versionConflict = '/errors/version-conflict';

  /// 426: the app is older than `ClientConfig.minimumAppVersion`.
  static const upgradeRequired = '/errors/upgrade-required';

  /// Every catalogue type.
  static const Set<String> all = {
    validationFailed,
    rateLimited,
    versionConflict,
    upgradeRequired,
  };
}
