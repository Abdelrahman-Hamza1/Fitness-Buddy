import 'dart:async';

import 'package:fb_mobile/core/session/session_clock.dart';
import 'package:fb_mobile/core/session/session_service.dart';

/// Foreground wakeups share the coordinator's PA3 deadline and flight. This
/// owns only a timer, never a second retry count or wall-clock deadline.
final class SessionRetryScheduler {
  /// Construction does no I/O; [start] is exclusively post-first-frame.
  new({
    required this._service,
    required this._clock,
    this._schedule = Timer.new,
  }) {
    _service.addAttemptListener(reconcile);
  }

  final SessionService _service;
  final SessionClock _clock;
  final Timer Function(Duration, void Function()) _schedule;
  Timer? _timer;
  Duration? _scheduledAt;
  bool _started = false;
  bool _foreground = false;
  bool _disposed = false;

  /// Activates deferred startup; background startup waits for a resume.
  void start({required bool foreground}) {
    if (_started || _disposed) return;
    _started = true;
    _foreground = foreground;
    wake();
  }

  /// Backgrounding retains the service's failure count/deadline.
  void setForeground({required bool foreground}) {
    if (_disposed) return;
    _foreground = foreground;
    if (!foreground) {
      _cancel();
    } else {
      wake();
    }
  }

  /// Resume and successful origin-bound transport notifications only wake;
  /// they never reset or shorten backoff. Errors stay inside this task.
  void wake() {
    if (!_started || !_foreground || _disposed) return;
    if (_clock.elapsed < _service.nextAttemptAt) {
      reconcile();
      return;
    }
    _cancel();
    // SessionService alone owns flight deduplication and account fencing.
    unawaited(_attempt());
  }

  Future<void> _attempt() async {
    try {
      await _service.startAfterFirstFrame();
    } on Object {
      // The coordinator exposes typed token-free state. Never forward raw
      // transport/plugin exceptions to Flutter's global error handler.
    } finally {
      reconcile();
    }
  }

  /// Called after every coordinator flight, including interceptor failures.
  void reconcile() {
    if (!_started ||
        !_foreground ||
        _disposed ||
        !_service.canRetryAutomatically) {
      _cancel();
      return;
    }
    final deadline = _service.nextAttemptAt;
    if (_timer != null && _scheduledAt == deadline) return;
    _cancel();
    final remaining = deadline - _clock.elapsed;
    _scheduledAt = deadline;
    _timer = _schedule(
      remaining > Duration.zero ? remaining : Duration.zero,
      () {
        _timer = null;
        _scheduledAt = null;
        wake();
      },
    );
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _scheduledAt = null;
  }

  /// Removes notifications and the sole retry timer.
  /// Late flights cannot arm it.
  void dispose() {
    _disposed = true;
    _cancel();
    _service.removeAttemptListener(reconcile);
  }
}
