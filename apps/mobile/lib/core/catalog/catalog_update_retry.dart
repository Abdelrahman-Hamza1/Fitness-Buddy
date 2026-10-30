import 'dart:async';

/// One check with exactly one retry, keyed to session readiness (A24 review
/// #6, fix check #2). The caller starts watching readiness **before** [run]
/// and calls [ready] whenever the session becomes ready:
/// - ready while the first attempt is in flight, and it then fails: the
///   retry runs immediately;
/// - ready after the first attempt failed: the retry runs then;
/// - the first attempt succeeded, or the retry was used: [ready] is a no-op.
///
/// The retry's own failure is swallowed: the next launch tries again.
final class OneRetry {
  /// Retries `attempt` at most once.
  new(this._attempt);

  final Future<void> Function() _attempt;
  bool _running = false;
  bool _readyWhileRunning = false;
  bool _failed = false;
  bool _succeeded = false;
  bool _retried = false;

  /// Whether nothing more will run (success, or the retry was used).
  bool get finished => _succeeded || _retried;

  /// The first attempt. Returns whether it succeeded. Never throws.
  Future<bool> run() async {
    _running = true;
    try {
      await _attempt();
      _succeeded = true;
      return true;
    } on Object {
      _failed = true;
      if (_readyWhileRunning) _retry();
      return false;
    } finally {
      _running = false;
    }
  }

  /// The session became ready.
  void ready() {
    if (finished) return;
    if (_running) {
      _readyWhileRunning = true;
    } else if (_failed) {
      _retry();
    }
  }

  void _retry() {
    if (_retried) return;
    _retried = true;
    unawaited(_attempt().then<void>((_) {}, onError: (Object _) {}));
  }
}
