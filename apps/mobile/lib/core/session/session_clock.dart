import 'package:fb_domain/fb_domain.dart';

/// Wall time is only an expiry hint; retries and freshness use elapsed time.
abstract interface class SessionClock {
  /// UTC wall time, allowed to jump.
  DateTime get wallNow;

  /// Elapsed time that never moves backwards within this process.
  Duration get elapsed;
}

/// Uses the injected app clock and a process-local stopwatch.
final class ElapsedSessionClock implements SessionClock {
  /// Starts no I/O or timers.
  new(this._wall) : _watch = Stopwatch()..start();

  final Clock _wall;
  final Stopwatch _watch;

  @override
  DateTime get wallNow => _wall.nowUtc();

  @override
  Duration get elapsed => _watch.elapsed;
}
