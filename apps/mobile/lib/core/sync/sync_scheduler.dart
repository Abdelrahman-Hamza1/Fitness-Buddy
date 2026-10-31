import 'dart:async';
import 'dart:math';

import 'package:fb_sync/fb_sync.dart';

/// How a scheduled run ended (A34 D10, D11).
sealed class SyncRunOutcome {
  const new();
}

/// The run finished.
final class SyncRunSucceeded extends SyncRunOutcome {
  /// A success.
  const new();
}

/// The run didn't start (signed out, a guest, a transition, paused).
final class SyncRunSkipped extends SyncRunOutcome {
  /// A skip.
  const new();
}

/// The run stopped with [kind]; [retryAfter] from the server, if any.
final class SyncRunFailed extends SyncRunOutcome {
  /// A failure.
  const new(this.kind, {this.retryAfter});

  /// Why.
  final SyncFailureKind kind;

  /// The server's requested wait.
  final Duration? retryAfter;
}

/// When sync runs (A34 D10, D11): debounced after local changes, on
/// foreground, on a reconnect signal, on demand; one run at a time (a
/// trigger during a run queues exactly one more); exponential backoff with
/// jitter after a failure, only while in the foreground. No polling and no
/// background work. Pure timing logic; the runner does the work.
final class SyncScheduler {
  /// A scheduler calling [_run]. `schedule` makes timers (tests pass a
  /// fake); `random` gives the jitter.
  new(
    this._run, {
    this.debounce = const Duration(seconds: 3),
    this._schedule = Timer.new,
    Random? random,
    DateTime Function()? now,
  }) : _random = random ?? Random(),
       _now = now ?? DateTime.now;

  final Future<SyncRunOutcome> Function() _run;
  final Timer Function(Duration, void Function()) _schedule;
  final Random _random;
  final DateTime Function() _now;

  /// No automatic run before this (the last failure's backoff, A34 fix 7);
  /// a local edit's debounce never undercuts it.
  DateTime? _retryAt;

  /// No automatic run before this (the server's `Retry-After`): foreground
  /// and reconnect signals reset the backoff but respect this.
  DateTime? _serverRetryAt;

  /// The quiet time after a local change before a run.
  final Duration debounce;

  /// The first retry delay after a failure.
  static const Duration firstBackoff = Duration(seconds: 30);

  /// The longest retry delay.
  static const Duration maxBackoff = Duration(minutes: 15);

  Timer? _timer;
  Future<SyncRunOutcome>? _running;
  bool _again = false;
  bool _foreground = true;
  bool _started = false;
  bool _disposed = false;
  int _failures = 0;

  /// The number of failed runs in a row.
  int get failures => _failures;

  /// Whether a run is in flight.
  bool get running => _running != null;

  /// Whether the app is in the foreground (runs and requests only then).
  bool get foreground => _foreground;

  /// Starts scheduling. Called after the first frame and the session start
  /// (never on the startup path, UX-001): one attempt now if in the
  /// foreground (the runner skips it until a session is ready; the session
  /// becoming ready triggers [reconnected]).
  void start({required bool foreground}) {
    if (_started || _disposed) return;
    _started = true;
    _foreground = foreground;
    if (foreground) unawaited(_start());
  }

  /// A local change set committed: run after [debounce] of quiet.
  void localChange() {
    if (!_started || _disposed) return;
    if (_running != null) {
      _again = true;
      return;
    }
    if (!_foreground) return;
    _arm(_atLeast(debounce, _later(_retryAt, _serverRetryAt)));
  }

  static DateTime? _later(DateTime? a, DateTime? b) =>
      a == null ? b : (b == null || a.isAfter(b) ? a : b);

  /// [delay], or longer until [deadline].
  Duration _atLeast(Duration delay, DateTime? deadline) {
    if (deadline == null) return delay;
    final wait = deadline.difference(_now());
    return wait > delay ? wait : delay;
  }

  /// The app came to the foreground or left it.
  void setForeground({required bool foreground}) {
    if (!_started || _disposed) return;
    _foreground = foreground;
    if (!foreground) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _resetBackoff();
    _trigger();
  }

  /// The network or the session came back: run now, backoff reset (a
  /// server `Retry-After` still holds).
  void reconnected() {
    if (!_started || _disposed || !_foreground) return;
    _resetBackoff();
    _trigger();
  }

  void _resetBackoff() {
    _failures = 0;
    _retryAt = null;
  }

  /// "Sync now" or pull-to-refresh: runs now and completes when the run
  /// (or the queued one after the current) finished.
  Future<SyncRunOutcome> syncNow() {
    if (_disposed) return Future.value(const SyncRunSkipped());
    _resetBackoff();
    _serverRetryAt = null;
    _timer?.cancel();
    _timer = null;
    final running = _running;
    if (running != null) {
      _again = true;
      // The queued run if the current one started it, else a fresh one.
      return running.then((_) {
        if (_running case final next?) return next;
        _timer?.cancel();
        _timer = null;
        return _start();
      });
    }
    return _start();
  }

  void _trigger() {
    _timer?.cancel();
    _timer = null;
    if (_running != null) {
      _again = true;
      return;
    }
    final server = _serverRetryAt;
    if (server != null && server.isAfter(_now())) {
      _arm(server.difference(_now()));
      return;
    }
    unawaited(_start());
  }

  void _arm(Duration delay) {
    _timer?.cancel();
    _timer = _schedule(delay, () {
      _timer = null;
      if (_running != null) {
        _again = true;
      } else {
        unawaited(_start());
      }
    });
  }

  Future<SyncRunOutcome> _start() {
    final run = _running = _guardedRun();
    return run;
  }

  Future<SyncRunOutcome> _guardedRun() async {
    SyncRunOutcome outcome;
    try {
      outcome = await _run();
    } on Object {
      outcome = const SyncRunFailed(SyncFailureKind.server);
    }
    _running = null;
    if (_disposed) return outcome;
    switch (outcome) {
      case SyncRunSucceeded():
        _resetBackoff();
        _serverRetryAt = null;
        // A run queued during this one starts only in the foreground; the
        // next foreground runs anyway (A34 fix 6).
        if (_again && _foreground) {
          _again = false;
          unawaited(_start());
        }
      case SyncRunSkipped():
        _again = false;
      case SyncRunFailed(:final kind, :final retryAfter):
        _again = false;
        _failures++;
        if (_retries(kind)) {
          final delay = retryAfter ?? backoff(_failures);
          _retryAt = _now().add(delay);
          if (retryAfter != null) _serverRetryAt = _retryAt;
          if (_foreground) _arm(delay);
        }
    }
    return outcome;
  }

  /// Failures that wait for a signal (sign-in, an update) instead of a
  /// timer.
  static bool _retries(SyncFailureKind kind) => switch (kind) {
    SyncFailureKind.unauthorized ||
    SyncFailureKind.forbidden ||
    SyncFailureKind.upgradeRequired => false,
    _ => true,
  };

  /// The delay before retry number [failures] (1-based): 30 s × 2ⁿ⁻¹,
  /// capped at 15 min, ±20 % jitter.
  Duration backoff(int failures) {
    final exponent = min(failures - 1, 10);
    final base = min(
      firstBackoff.inMilliseconds * pow(2, exponent).toInt(),
      maxBackoff.inMilliseconds,
    );
    final jitter = 0.8 + _random.nextDouble() * 0.4;
    return Duration(milliseconds: (base * jitter).round());
  }

  /// Stops every timer; later triggers do nothing.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
